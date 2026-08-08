variable "bucket_name" {
  description = "Prefijo del nombre del bucket (se le añade un sufijo aleatorio para garantizar unicidad global)"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod, etc.), usado como tag"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags adicionales para el bucket"
  type        = map(string)
  default     = {}
}

variable "upload_object" {
  description = "Si es true, sube un objeto al bucket usando object_source/object_key"
  type        = bool
  default     = false
}

variable "object_key" {
  description = "Key (ruta) del objeto dentro del bucket"
  type        = string
  default     = "index.html"
}

variable "object_source" {
  description = "Ruta local del archivo a subir (requerido si upload_object = true)"
  type        = string
  default     = ""
}

variable "object_content_type" {
  description = "Content-Type del objeto subido"
  type        = string
  default     = "text/html"
}
