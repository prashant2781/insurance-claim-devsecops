resource "aws_ecs_task_definition" "claim_service" {
  family                   = "${local.resource_prefix}-service"
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
      name      = "claim-service"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          name          = "claim-service-http"
          containerPort = 8080
          hostPort      = 8080
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
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.claim_service.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "claim-service"
        }
      }
    }
  ])

  tags = {
    Name = "${local.resource_prefix}-task-definition"
  }
}

resource "aws_ecs_service" "claim_service" {
  # checkov:skip=CKV_AWS_333:Public IP is intentional in DEV to avoid NAT Gateway cost; inbound access remains restricted to the ALB
  name            = "${local.resource_prefix}-service"
  cluster         = aws_ecs_cluster.dev.id
  task_definition = aws_ecs_task_definition.claim_service.arn
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
    target_group_arn = aws_lb_target_group.claim_service.arn
    container_name   = "claim-service"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.task_execution
  ]

  tags = {
    Name = "${local.resource_prefix}-service"
  }
}
