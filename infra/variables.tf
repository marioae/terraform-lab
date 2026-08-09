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

variable "ecs_app_name" {
  description = "Nombre base para cluster/servicio/ALB/repo ECR del demo ECS Fargate — obligatorio, viene del .tfvars del ambiente (ver envs/)"
  type        = string
}

variable "ecs_image_tag" {
  description = "Tag de la imagen en ECR que el servicio ECS despliega (debe existir en el repo antes de que las tareas arranquen sanas)"
  type        = string
  default     = "latest"
}
