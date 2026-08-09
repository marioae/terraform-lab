
output "bucket_name" {
  description = "Nombre del bucket que dispara la Lambda"
  value       = module.bucket.bucket_name
}

output "function_name" {
  description = "Nombre de la función Lambda"
  value       = module.notifier.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda"
  value       = module.notifier.function_arn
}

output "ecs_ecr_repository_url" {
  description = "URL del repo ECR del demo ECS — usar para docker tag/push antes del primer deploy sano"
  value       = module.ecs_app.ecr_repository_url
}

output "ecs_alb_dns_name" {
  description = "DNS público del ALB del demo ECS (http://<valor>)"
  value       = module.ecs_app.alb_dns_name
}
