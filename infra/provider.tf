provider "aws" {
  region = var.aws_region
  # Localmente: setear $env:AWS_PROFILE = "mae" antes de correr terraform (no hardcodear el profile aquí).
  # En CI: las credenciales llegan por variables de entorno AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
}
