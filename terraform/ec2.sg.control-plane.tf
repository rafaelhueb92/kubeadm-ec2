resource "aws_security_group" "control_plane" {
  name        = var.ec2_info.control_plane_sg
  description = "Allow https inbound traffic"
  vpc_id      = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "allow_admin_ip" {
  type              = "ingress"
  description       = "https access from source IP"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.ec2_info.source_ip]
  security_group_id = aws_security_group.control_plane.id

  depends_on = [aws_security_group.control_plane]
}

resource "aws_security_group_rule" "self_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.control_plane.id
  self              = true
}

resource "aws_security_group_rule" "allow_worker_traffic" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.control_plane.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "allow_nlb_health_checks" {
  type              = "ingress"
  description       = "NLB health checks and internal VPC traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [module.network.vpc_cidr]
  security_group_id = aws_security_group.control_plane.id
}
