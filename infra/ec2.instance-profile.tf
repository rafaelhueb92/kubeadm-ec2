resource "aws_iam_instance_profile" "this" {
  name = var.ec2_info.instance_profile_name
  role = aws_iam_role.role.name
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.ec2_info.role_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.policy_document.json
}