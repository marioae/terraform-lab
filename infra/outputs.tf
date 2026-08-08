
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
