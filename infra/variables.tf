variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Prefijo del nombre del bucket S3 que dispara la Lambda — obligatorio, viene del .tfvars del ambiente (ver envs/)"
  type        = string
}

variable "environment" {
  description = "Nombre del ambiente (dev, uat, prod) — obligatorio, viene del .tfvars del ambiente (ver envs/)"
  type        = string
}

variable "function_name" {
  description = "Nombre de la función Lambda — obligatorio, viene del .tfvars del ambiente (ver envs/)"
  type        = string
}
