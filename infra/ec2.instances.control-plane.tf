module "ec2_control_plane_instance" {
  source = "./modules/ec2"

  launch_template = {
    name                                 = var.control_plane_launch_template.name
    image_id                             = data.aws_ami.this.image_id
    vpc_security_group_ids               = [aws_security_group.control_plane.id]
    key_name                             = aws_key_pair.this.key_name
    instance_profile_name                = aws_iam_instance_profile.this.name
    disabling_api_termination            = var.control_plane_launch_template.disabling_api_termination
    disable_api_stop                     = var.control_plane_launch_template.disable_api_stop
    instance_type                        = var.control_plane_launch_template.instance_type
    instance_initiated_shutdown_behavior = var.control_plane_launch_template.instance_initiated_shutdown_behavior
    user_data                            = filebase64(var.control_plane_launch_template.user_data)
    ebs = {
      volume_size           = var.control_plane_launch_template.ebs.volume_size
      delete_on_termination = var.control_plane_launch_template.ebs.delete_on_termination

    }
  }
  auto_scalling_group = {
    name                      = var.control_plane_auto_scalling_group.name
    max_size                  = var.control_plane_auto_scalling_group.max_size
    min_size                  = var.control_plane_auto_scalling_group.min_size
    desired_capacity          = var.control_plane_auto_scalling_group.desired_capacity
    health_check_grace_period = var.control_plane_auto_scalling_group.health_check_grace_period
    health_check_type         = var.control_plane_auto_scalling_group.health_check_type
    vpc_zone_identifier       = module.network.private_subnet_ids
    target_group_arns         = [aws_lb_target_group.nlb_tcp.arn]
    instance_tags = merge(
      var.tags,
      { PatchGroup = var.patch_group },
      var.control_plane_auto_scalling_group.instance_tags
    )
    instance_maintenance_policy = {
      min_healthy_percentage = var.control_plane_auto_scalling_group.instance_maintenance_policy.min_healthy_percentage
      max_healthy_percentage = var.control_plane_auto_scalling_group.instance_maintenance_policy.max_healthy_percentage
    }
  }
  tags = var.tags
}
