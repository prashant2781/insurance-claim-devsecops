output "alb_dns_name" {
  description = "Public DNS name of the DEV Application Load Balancer"
  value       = aws_lb.claim_service.dns_name
}

output "application_url" {
  description = "HTTP URL of the DEV Insurance Claim Service"
  value       = "http://${aws_lb.claim_service.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the DEV ECS cluster"
  value       = aws_ecs_cluster.dev.name
}

output "ecs_service_name" {
  description = "Name of the DEV ECS service"
  value       = aws_ecs_service.claim_service.name
}

output "task_definition_arn" {
  description = "ARN of the registered Claim Service task definition"
  value       = aws_ecs_task_definition.claim_service.arn
}

output "target_group_arn" {
  description = "ARN of the Claim Service target group"
  value       = aws_lb_target_group.claim_service.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for the Claim Service"
  value       = aws_cloudwatch_log_group.claim_service.name
}
