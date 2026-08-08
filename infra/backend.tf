# Backend remoto para el state de infra/.
# El bucket NO lo gestiona Terraform (se crea manualmente, ver README > "Backend remoto").
#
# Sin "profile" a propósito: local usa $env:AWS_PROFILE = "mae" (mismo mecanismo
# que provider.tf); en CI usa AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY (secrets).
# Los bloques backend no aceptan variables, así que no se puede parametrizar por
# entorno dentro de este archivo — tiene que resolverse desde afuera.
#
# Multi-ambiente vía Terraform workspaces (dev/uat/prod): un mismo "key" acá,
# pero cada workspace no-default se guarda aparte dentro del mismo bucket, en
# env:/<workspace>/infra/terraform.tfstate — no requiere un bucket/backend por
# ambiente. Ver README > "Ambientes (dev/uat/prod)".
terraform {
  backend "s3" {
    bucket = "terraform-states-07082026"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
