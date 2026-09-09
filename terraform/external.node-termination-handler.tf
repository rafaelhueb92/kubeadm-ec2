data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.region
  account    = data.aws_caller_identity.current.account_id
  queue_name = "NodeTerminationQueue"
}

data "aws_iam_policy_document" "node_termination_queue_policy" {
  statement {

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage",
    ]
    resources = ["arn:aws:sqs:${local.region}:${local.account}:${local.queue_name}"]
  }
}

resource "aws_sqs_queue" "termination" {
  name                      = local.queue_name
  message_retention_seconds = 300
  policy                    = data.aws_iam_policy_document.node_termination_queue_policy.json
}

data "aws_iam_policy_document" "node_termination_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "node_termination" {
  statement {
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "node_termination_handler_policy" {
  name   = "NodeTerminationHandlerPolicy"
  policy = data.aws_iam_policy_document.node_termination.json
}

resource "aws_iam_role" "node_termination_handler" {
  name               = "NodeTerminationHandlerRole"
  assume_role_policy = data.aws_iam_policy_document.node_termination_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "auto_scaling_notification_access" {
  role       = aws_iam_role.node_termination_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScallingNotificationAccessRole"
}

resource "aws_iam_role_policy_attachment" "node_termination_handler_policy_attachment" {
  role       = aws_iam_role.node_termination_handler.name
  policy_arn = aws_iam_policy.node_termination_handler_policy.arn
}

resource "aws_autoscaling_lifecycle_hook" "node_termination_hook" {
  name                    = "NodeTerminationHook"
  autoscaling_group_name  = module.ec2_worker_instance.auto_scalling_group_name
  default_result          = "CONTINUE"
  heartbeat_timeout       = 300
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sqs_queue.termination.arn
  role_arn                = aws_iam_role.node_termination_handler.arn
}
