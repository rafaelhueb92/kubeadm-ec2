resource "aws_autoscaling_group" "this" {
  name                      = var.auto_scalling_group.name
  max_size                  = var.auto_scalling_group.max_size
  min_size                  = var.auto_scalling_group.min_size
  desired_capacity          = var.auto_scalling_group.desired_capacity
  health_check_grace_period = var.auto_scalling_group.health_check_grace_period
  target_group_arns         = var.auto_scalling_group.target_group_arns
  health_check_type         = var.auto_scalling_group.health_check_type
  vpc_zone_identifier       = var.auto_scalling_group.vpc_zone_identifier

  launch_template {
    name    = aws_launch_template.this.name
    version = "$Latest"
  }

  instance_maintenance_policy {
    min_healthy_percentage = var.auto_scalling_group.instance_maintenance_policy.min_healthy_percentage
    max_healthy_percentage = var.auto_scalling_group.instance_maintenance_policy.max_healthy_percentage
  }

  dynamic "tag" {
    for_each = var.auto_scalling_group.instance_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }

  }

  #tag {
  #  key                 = "Environment"
  #  value               = var.tags.Environment
  #  propagate_at_launch = true
  #}

  #tag {
  #  key                 = "Project"
  #  value               = var.tags.Project
  #  propagate_at_launch = false
  #}

  #tag { 
  #  key     = "Patch Group"
  #  value   = "Production"
  #  propagate_at_launch = flase
  #}

}
