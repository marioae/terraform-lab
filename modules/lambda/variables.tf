variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "description" {
  description = "Descripción de la función"
  type        = string
  default     = ""
}

variable "source_dir" {
  description = "Carpeta local con el código fuente de la Lambda (se empaqueta en un zip automáticamente)"
  type        = string
}

variable "handler" {
  description = "Handler de entrada (formato archivo.función)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime de Lambda"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Timeout en segundos"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Memoria asignada en MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Variables de entorno para la función"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags adicionales para la función"
  type        = map(string)
  default     = {}
}
