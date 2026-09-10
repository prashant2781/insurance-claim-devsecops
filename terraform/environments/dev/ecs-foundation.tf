resource "aws_ecs_cluster" "dev" {
  name = "${local.resource_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.resource_prefix}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "claim_service" {
  # checkov:skip=CKV_AWS_158:Customer-managed KMS encryption will be enabled in QA and PROD
  # checkov:skip=CKV_AWS_338:Seven-day retention is intentional for the cost-aware DEV environment
  name              = "/ecs/${local.resource_prefix}-service"
  retention_in_days = 7

  tags = {
    Name = "${local.resource_prefix}-logs"
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    sid     = "AllowEcsTasksToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.resource_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = {
    Name = "${local.resource_prefix}-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${local.resource_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = {
    Name = "${local.resource_prefix}-task-role"
  }
}
