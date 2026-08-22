module "ec2_worker_instance" {
  source                  = "./modules/ec2"
  image_id                = data.aws_ami.this.image_id
  vpc_security_groups_ids = [aws_security_group.allow_ssh.id]
  key_name                = aws_key_pair.this.key_name
  instance_profile_name   = aws_iam_instance_profile.this.name
  vpc_zone_identifier     = module.network.private_subnet_ids
  launch_template = {
    name                                 = var.worker_launch_template.name
    disabling_api_termination            = var.worker_launch_template.disabling_api_termination
    disable_api_stop                     = var.worker_launch_template.disable_api_stop
    instance_type                        = var.worker_launch_template.instance_type
    instance_initiated_shutdown_behavior = var.worker_launch_template.instance_initiated_shutdown_behavior
    ebs = {
      volume_size           = var.worker_launch_template.ebs.volume_size
      delete_on_termination = var.worker_launch_template.ebs.delete_on_termination
    }
  }
  auto_scalling_group = {
    name                      = var.worker_auto_scalling_group.name
    max_size                  = var.worker_auto_scalling_group.max_size
    min_size                  = var.worker_auto_scalling_group.min_size
    desired_capacity          = var.worker_auto_scalling_group.desired_capacity
    health_check_grace_period = var.worker_auto_scalling_group.health_check_grace_period
    health_check_type         = var.worker_auto_scalling_group.health_check_type
    instance_maintenance_policy = {
      min_healthy_percentage = var.worker_auto_scalling_group.instance_maintenance_policy.min_healthy_percentage
      max_healthy_percentage = var.worker_auto_scalling_group.instance_maintenance_policy.max_healthy_percentage
    }
  }
  tags = var.tags
}