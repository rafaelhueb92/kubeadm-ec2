resource "aws_lb" "nlb_control_plane" {
  name                        = var.nlb_control_plane.name
  internal                    = var.nlb_control_plane.internal # Is internet facing or internal (VPC ONLY)
  load_balancer_type          = var.nlb_control_plane.load_balancer_type
  subnets                     = data.aws_subnets.private_subnets.ids

  enable_deletion_protection = var.nlb_control_plane.enable_deletion_protection

  tags = var.tags

}
