output "key_pair_private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

output "nlb_dns_name" {
  value = aws_lb.nlb_control_plane.dns_name
}

output "worker_launch_template_id" {
  value = module.ec2_worker_instance.launch_template_id
}

output "node_termination_queue_url" {
  value = aws_sqs_queue.termination.id
}
