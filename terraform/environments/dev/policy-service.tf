variable "policy_container_image" {
  description = "Immutable digest-based ECR image URI for the Policy Service"
  type        = string

  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.policy_container_image))
    error_message = "Policy container image must use an immutable SHA-256 digest."
  }
}

resource "aws_cloudwatch_log_group" "policy_service" {
  # checkov:skip=CKV_AWS_158:Customer-managed KMS encryption will be enabled in QA and PROD
  # checkov:skip=CKV_AWS_338:Seven-day retention is intentional for the cost-aware DEV environment
  name              = "/ecs/${local.resource_prefix}-policy-service"
  retention_in_days = 7

  tags = {
    Name    = "${local.resource_prefix}-policy-logs"
    Service = "policy-service"
  }
}

resource "aws_lb_target_group" "policy_service" {
  # checkov:skip=CKV_AWS_378:ALB-to-container HTTP is accepted only in the isolated DEV network; PROD will evaluate end-to-end TLS
  name        = "${local.resource_prefix}-policy-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dev.id

  deregistration_delay = 30

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${local.resource_prefix}-policy-tg"
    Service = "policy-service"
  }
}

resource "aws_lb_listener_rule" "policy_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.policy_service.arn
  }

  condition {
    path_pattern {
      values = [
        "/policies",
        "/policies/*"
      ]
    }
  }

  tags = {
    Name    = "${local.resource_prefix}-policy-routing"
    Service = "policy-service"
  }
}

resource "aws_ecs_task_definition" "policy_service" {
  family                   = "${local.resource_prefix}-policy-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "policy-service"
      image     = var.policy_container_image
      essential = true

      portMappings = [
        {
          name          = "policy-service-http"
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      readonlyRootFilesystem = true

      linuxParameters = {
        initProcessEnabled = true
      }

      environment = [
        {
          name  = "APP_ENV"
          value = "dev"
        },
        {
          name  = "ALLOWED_ORIGINS"
          value = var.allowed_origins
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.policy_service.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "policy-service"
        }
      }
    }
  ])

  tags = {
    Name    = "${local.resource_prefix}-policy-task-definition"
    Service = "policy-service"
  }
}

resource "aws_ecs_service" "policy_service" {
  # checkov:skip=CKV_AWS_333:Public IP is intentional in DEV to avoid NAT Gateway cost; inbound access remains restricted to the ALB
  name            = "${local.resource_prefix}-policy-service"
  cluster         = aws_ecs_cluster.dev.id
  task_definition = aws_ecs_task_definition.policy_service.arn
  desired_count   = 1

  launch_type         = "FARGATE"
  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    security_groups = [
      aws_security_group.ecs_tasks.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.policy_service.arn
    container_name   = "policy-service"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener_rule.policy_service,
    aws_iam_role_policy_attachment.task_execution
  ]

  tags = {
    Name    = "${local.resource_prefix}-policy-service"
    Service = "policy-service"
  }
}
