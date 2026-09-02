variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)

}

variable "auto_scalling_group" {
  type = object({
    name                      = string
    max_size                  = number
    min_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
    health_check_type         = string
    vpc_zone_identifier       = list(string)
    target_group_arns         = list(string)
    instance_tags             = map(string)
    instance_maintenance_policy = object({
      min_healthy_percentage = number
      max_healthy_percentage = number
    })
  })
}

variable "launch_template" {
  type = object({
    name                                 = string
    disabling_api_termination            = bool
    disable_api_stop                     = bool
    instance_type                        = string
    instance_initiated_shutdown_behavior = string
    ebs = object({
      volume_size           = number
      delete_on_termination = bool
    })
    user_data              = string
    key_name               = string
    image_id               = string
    instance_profile_name  = string
    vpc_security_group_ids = list(string)
  })
}
