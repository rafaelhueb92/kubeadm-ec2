resource "aws_s3_bucket" "ansible-ssm" {
  bucket = var.bucket_ssm

  tags = var.tags
}
