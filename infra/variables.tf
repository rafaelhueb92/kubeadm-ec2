variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "ec2-dnv-class"
  }
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ec2_info" {
  description = "Information about the EC2 instance to create"
  type = object({
    ami                   = string
    instance_type         = string
    key_name              = string
    instance_profile_name = string
    role_name             = string
    source_ip             = string
  })
  default = {
    ami                   = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
    instance_type         = "t2.micro"
    key_name              = "ec2-key"
    instance_profile_name = "ec2-instance-profile"
    role_name             = "ec2-role"
    source_ip             = "189.62.46.74/32"
  }
}

variable "control_plane_auto_scalling_group" {
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

variable "control_plane_launch_template" {
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

variable "worker_auto_scalling_group" {
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
    name                      = "production-asg-worker"
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

variable "worker_launch_template" {
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
    name                                 = "production-debian-worker-lt"
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