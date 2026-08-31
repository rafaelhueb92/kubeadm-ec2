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

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "write_patching_logs" {
  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    resources = [
      "${aws_s3_bucket.logs.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "write_patching_logs" {
  name   = "write-patching-logs"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.write_patching_logs.json
}
