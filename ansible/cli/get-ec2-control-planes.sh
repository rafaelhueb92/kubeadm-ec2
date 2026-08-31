aws ec2 describe-instances \           
  --filters "Name=tag:1,Values=production-control-plane" --query "Reservations[*].Instances[*].InstanceId" \
--output text >> ../ansible/production

echo "=============================================="
echo "Check Status"
echo "=============================================="

aws ec2 describe-instances \
       --filters "Name=tag:1,Values=production-control-plane" --query "Reservations[*].Instances[*].[InstanceId,State.Name]"

aws ec2 get-console-output \
      --instance-id i-049575c9063de939d \
      --latest \
      --output text

   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name <asg-name> \
     --preferences '{"MinHealthyPercentage": 50}'

   terraform apply -replace=module.ec2_control_plane_instance.aws_autoscaling_group.this \
                   -replace=module.ec2_worker_instance.aws_autoscaling_group.this

aws ssm start-session --target <ec2-id> 