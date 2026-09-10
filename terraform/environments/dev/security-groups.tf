resource "aws_security_group" "alb" {
  name        = "${local.resource_prefix}-alb-sg"
  description = "Allow public HTTP traffic to the DEV Application Load Balancer"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name = "${local.resource_prefix}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  # checkov:skip=CKV_AWS_260:Public HTTP is permitted only on the DEV ALB; ECS tasks accept traffic only from the ALB security group
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow ALB traffic to ECS tasks on the application port"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.resource_prefix}-ecs-tasks-sg"
  description = "Allow Claim Service traffic only from the DEV ALB"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name = "${local.resource_prefix}-ecs-tasks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow Claim Service traffic only from the ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTPS for ECR, CloudWatch and AWS service access"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow DNS queries over UDP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow DNS queries over TCP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}
