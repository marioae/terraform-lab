output "ecr_repository_url" {
  description = "URL del repositorio ECR (usar para docker tag / docker push)"
  value       = aws_ecr_repository.this.repository_url
}

output "cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.this.name
}

output "alb_dns_name" {
  description = "DNS público del Load Balancer (http://<valor>)"
  value       = aws_lb.this.dns_name
}
