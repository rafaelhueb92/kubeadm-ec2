# Postmortem: NLB Health Checks Failing on Kubernetes Control Plane

- **Date:** 2026-09-03
- **Status:** Resolved
- **Severity:** High (control-plane load balancer had zero healthy targets)
- **Component:** `production-control-plane-nlb` → target group `prod-cp-tg-default` (port 6443), control-plane ASG
- **Author:** Rafael Hueb

## Summary

All four control-plane targets registered in the internal NLB target group
`prod-cp-tg-default` were reported `unhealthy` (`Target.FailedHealthChecks`).
Two independent root causes were found:

1. The `control-plane-sg` security group did not allow traffic from the NLB
   health-check sources (the NLB node ENIs), so TCP probes to port 6443 were
   silently dropped.
2. Only one of the four control-plane instances was running `kube-apiserver`.
   The remaining three were never joined to the cluster, so nothing listened on
   port 6443 on those instances.

The NLB was unusable as a control-plane endpoint: `0/4` targets healthy.

## Timeline (UTC)

| Time | Event |
|---|---|
| ~2026-09-01 | `create nlb` commit (c26003b) introduces NLB + target group with `health_check_type = EC2` ASG. |
| 2026-09-03 (earlier) | Cluster initialized on `control_planes[0]` only (`site.kube.init.yml` targets `control_planes[0]`); control-plane ASG runs 4 instances. |
| 2026-09-03 | Health check investigation started. `describe-target-health` shows `0/4 unhealthy`. |
| 2026-09-03 | Live inspection: NLB ENI IPs identified (10.0.10.169 / 10.0.11.60); `control-plane-sg` ingress only permits admin IP `189.62.46.74/32`, worker SG, and self. |
| 2026-09-03 | SSM checks on all 4 targets: kube-apiserver listening on 6443 only on `i-0550fdf12e4af4ff2`; kubelet `inactive` and no 6443 listener on the other three. |
| 2026-09-03 | Fix 1 applied (SG rule allowing VPC CIDR ingress). First master flips to `healthy`. |
| 2026-09-03 | Fix 2 applied: remaining three control planes join the cluster via `kubeadm join --config` with uploaded certs. |
| 2026-09-03 | Final check: `4/4` targets healthy; all four nodes present in `kubectl get nodes` as control-plane. |

## Root Causes

### Root cause 1 — Security group blocks NLB health-check probes

For a TCP health check to succeed, the NLB must establish a TCP connection to
the target on port 6443. Health checks originate from the NLB node ENIs, which
live inside the VPC but carry **no security group**. The `control-plane-sg`
ingress rules allowed only:

- `189.62.46.74/32` (operator public IP)
- `worker-sg` (source security group)
- itself (self-referencing)

None of these matched the NLB probe source addresses, so every probe was
dropped.

**Evidence:** target `i-0550fdf12e4af4ff2` was confirmed listening on 6443
(`ss` showed `kube-apiserver` bound, kubelet `active`) and yet was still
reported `unhealthy` — a listener that never receives the probe cannot pass.

**Fix:** added `allow_nlb_health_checks`, an all-traffic ingress rule from the
VPC CIDR (`10.0.0.0/16`) on the control-plane SG. The VPC CIDR is used rather
than the concrete NLB ENI IPs because ENI addresses change if the load
balancer is recreated, and ENIs carry no SG that could be referenced.

### Root cause 2 — Only 1 of 4 control planes was running kube-apiserver

The control-plane ASG (`desired_capacity = 4`) is attached to the target
group, but the bootstrap pipeline only covers the first master:

- `ansible/site.kube.init.yml` runs the `kubeadm-init-first-master` role on
  `control_planes[0]` only.
- No join playbook existed for additional control planes.

The other three instances had the Kubernetes packages and CRI-O installed
(`site.yml`) but kubelet was `inactive` and nothing listened on 6443. Even with
correct SG rules, TCP health checks on those targets could never pass.

**Evidence:** SSM Run Command on each remaining target showed `kubeadm v1.37.0`
and `crio: active` but `kubelet: inactive`, no `/etc/kubernetes/kubelet.conf`,
and no 6443 listener.

**Fix:** new role `ansible/roles/kubeadm-join-control-plane/` and playbook
`ansible/site.kube.join.yml`:

1. On `control_planes[0]`: create a bootstrap token, generate a certificate
   key and upload the control-plane certificates
   (`kubeadm init phase upload-certs --upload-certs`), and compute the CA
   discovery hash.
2. On the remaining control planes: render `kubeadm-join.yml`
   (per-node `advertiseAddress`, NLB DNS as `apiServerEndpoint`) and run
   `kubeadm join --config`.
3. Idempotent: instances already holding `/etc/kubernetes/kubelet.conf` are
   skipped, so the playbook can be re-run after ASG scale-out or instance
   replacement.

The join was executed against the three live instances via SSM Run Command
(see open issue 3 below). All three reported successful control-plane joins and
etcd scaled out to the new members.

## Latent Defect Found During Investigation

The control-plane SG mixed an inline `ingress` block with standalone
`aws_security_group_rule` resources. The AWS provider merges the AWS-side
permission set (self + worker-SG rules) into the SG's inline attribute during
refresh and planned to **remove those rules on apply** — i.e. the next
`terraform apply` would have silently revoked worker→control-plane and
self-traffic, breaking worker communication and etcd peer traffic.

**Fix:** converted the inline admin-CIDR rule into a standalone
`allow_admin_ip` rule so the SG has no inline ingress at all — the same clean
pattern already used by `worker-sg`. Post-refactor plan: `2 to add, 0 to
change, 0 to destroy`; the self/worker permissions were confirmed present via
the EC2 API after apply.

## Resolution Verification

- `aws elbv2 describe-target-health` → `4/4 healthy` (was `0/4`).
- `ss -lnt | grep 6443` → listening on all four targets; kubelet `active`.
- `kubectl get nodes` → four control-plane nodes present
  (ip-10-0-10-210, ip-10-0-10-68, ip-10-0-11-217, ip-10-0-11-97).

## Files Changed

| File | Change |
|---|---|
| `infra/ec2.sg.control-plane.tf` | Added `allow_nlb_health_checks` (VPC CIDR ingress); moved inline admin rule to standalone `allow_admin_ip` rule |
| `infra/modules/network/outputs.tf` | New `vpc_cidr` output |
| `ansible/site.kube.join.yml` | New playbook to join remaining control planes |
| `ansible/roles/kubeadm-join-control-plane/` | New role (tasks: `terraform-output`, `gather-credentials`, `upload-template`, `kubeadm-join`; template `kubeadm-join.j2`) |
| `ansible/cli/run-ansible.sh` | Added `site.kube.join.yml` step |

## Open Issues / Follow-ups

1. **No CNI installed.** All four nodes report `NotReady` and `coredns` is
   `Pending` — a pod network (e.g. flannel/calico) was never deployed. TCP 6443
   health checks pass regardless, but the cluster cannot schedule workloads
   until a CNI is installed.
2. **Worker ASG instances were never joined.** No `kubeadm join` exists for the
   worker nodes (`site.yml` only installs packages/CRI-O).
3. **Local ansible `aws_ssm` connection is broken.** `ansible-playbook` fails
   with `[ERROR]: A worker was found in a dead state` immediately after
   `ESTABLISH SSM CONNECTION` (ansible-core 2.21 / Python 3.14 with the
   `amazon.aws aws_ssm` connection plugin). The joins were therefore executed
   through SSM Run Command instead of the playbook. The new role is
   syntax-checked but not run end-to-end; the connection issue must be fixed
   before the playbook can serve ASG scale-out.
4. **Dead configuration.** `nlb_control_plane_target_group.health_check` in
   `infra/variables.tf` (healthy 3 / unhealthy 3 / timeout 10) is never applied
   to the `aws_lb_target_group` resource — AWS defaults are in effect
   (interval 30s, healthy 5, unhealthy 2). Either wire the block into the
   resource or remove the variable keys.

## Lessons Learned

- NLB health checks originate from the VPC and carry no security group — SG
  rules must explicitly allow the VPC CIDR (or the NLB subnets) for targets.
- A healthy-service check (listener present but still `unhealthy`) is the
  fastest discriminator between an SG problem and an application problem.
- Attaching an ASG to a target group implies every instance must self-bootstrap
  into the service; first-master-only bootstrap silently fails the rest of the
  ASG. Multi-master join logic should exist before the ASG is scaled beyond 1.
- Never mix inline `ingress` blocks and standalone `aws_security_group_rule`
  resources for the same SG — the provider's state representation will try to
  revoke rules managed outside the inline block.
