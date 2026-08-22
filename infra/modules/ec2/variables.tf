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
    instance_maintenance_policy = object({
      min_healthy_percentage = number
      max_healthy_percentage = number
    })
  })
  default = {
    name                      = "production-asg-control-plane"
    max_size                  = 5
    min_size                  = 2
    desired_capacity          = 4
    health_check_grace_period = 180
    health_check_type         = "EC2"
    instance_maintenance_policy = {
      min_healthy_percentage = 100
      max_healthy_percentage = 110
    }
  }
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
  })
  default = {
    name                                 = "production-debian-control-plane-lt"
    disabling_api_termination            = true
    disable_api_stop                     = true
    instance_type                        = "t3.micro"
    instance_initiated_shutdown_behavior = "terminate"
    ebs = {
      volume_size           = 20
      delete_on_termination = true
    }
  }
}

variable "vpc_zone_identifier" {
  type = list(string)
}

variable "vpc_security_groups_ids" {
  type = list(string)
}

variable "instance_profile_name" {
  type = string
}

variable "key_name" {
  type = string
}

variable "image_id" {
  type = string
}