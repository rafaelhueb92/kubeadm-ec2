resource "aws_lb_target_group" "nlb_tcp" {
  name               = var.nlb_control_plane_target_group.name
  port               = var.nlb_control_plane_target_group.port
  target_type        = var.nlb_control_plane_target_group.target_type
  protocol           = var.nlb_control_plane_target_group.protocol
  vpc_id             = data.aws_vpc.default.id
  preserve_client_ip = var.nlb_control_plane_target_group.preserve_client_ip
  tags               = var.tags
}
