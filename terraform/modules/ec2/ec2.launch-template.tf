resource "aws_launch_template" "this" {
  name_prefix = var.launch_template.name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.launch_template.ebs.volume_size
      delete_on_termination = var.launch_template.ebs.delete_on_termination
    }
  }

  disable_api_termination              = var.launch_template.disabling_api_termination
  disable_api_stop                     = var.launch_template.disable_api_stop
  image_id                             = var.launch_template.image_id
  instance_type                        = var.launch_template.instance_type
  key_name                             = var.launch_template.key_name
  instance_initiated_shutdown_behavior = var.launch_template.instance_initiated_shutdown_behavior
  vpc_security_group_ids               = var.launch_template.vpc_security_group_ids
  user_data                            = var.launch_template.user_data

  iam_instance_profile {
    name = var.launch_template.instance_profile_name
  }

  tag_specifications {

    resource_type = "instance"

    tags = var.tags


  }

}