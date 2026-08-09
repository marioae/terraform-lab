variable "app_name" {
  description = "Nombre base para cluster, servicio, ALB, target group y repo ECR"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, uat, prod), usado como tag"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC donde se crean el ALB, las security groups y las tareas Fargate"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets (públicas) donde se despliegan el ALB y las tareas Fargate"
  type        = list(string)
}

variable "container_port" {
  description = "Puerto que expone el contenedor de la aplicación"
  type        = number
  default     = 80
}

variable "image_tag" {
  description = "Tag de la imagen en ECR a desplegar en el servicio"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "CPU de la task definition (unidades Fargate, ej. 256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memoria de la task definition en MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Número deseado de tareas Fargate corriendo"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
}
