resource "aws_lb_listener" "nlb_control_plane" {
  load_balancer_arn = aws_lb.nlb_control_plane.arn
  port              = var.nlb_control_plane_listener.port
  protocol          = var.nlb_control_plane_listener.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tcp.arn
  }
}
