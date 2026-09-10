resource "aws_lb" "claim_service" {
  # checkov:skip=CKV2_AWS_20:HTTP-to-HTTPS redirection requires the production ACM and DNS configuration
  # checkov:skip=CKV_AWS_150:Deletion protection is disabled only for the cost-aware disposable DEV environment
  # checkov:skip=CKV_AWS_131:HTTP is used temporarily in DEV; PROD will use ACM and HTTPS
  # checkov:skip=CKV_AWS_91:ALB access logging will be added with the central audit bucket in the multi-account milestone
  # checkov:skip=CKV2_AWS_28:WAF will be implemented for the production environment
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name = "${local.resource_prefix}-alb"
  }
}

resource "aws_lb_target_group" "claim_service" {
  # checkov:skip=CKV_AWS_378:ALB-to-container HTTP is accepted only in the isolated DEV network; PROD will evaluate end-to-end TLS
  name        = "${local.resource_prefix}-tg"
  port        = 8080
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
    Name = "${local.resource_prefix}-tg"
  }
}

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_103:TLS listener policy is not applicable to the temporary DEV HTTP listener
  # checkov:skip=CKV_AWS_2:HTTP listener is intentional for DEV; PROD will redirect HTTP to HTTPS using ACM
  load_balancer_arn = aws_lb.claim_service.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.claim_service.arn
  }
}
