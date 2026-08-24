resource "aws_security_group" "worker" {
  name        = var.ec2_info.worker_sg
  description = "Allow SSH inbound traffic"
  vpc_id      = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}