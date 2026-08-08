output "function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "ARN de invocación (útil para API Gateway u otros triggers)"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "ARN del rol de ejecución de la Lambda"
  value       = aws_iam_role.lambda_exec.arn
}
