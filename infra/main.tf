locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "s3-lambda"
  }
}

# VPC default de la cuenta/región — el ALB y las tareas Fargate se despliegan ahí.
# Si la cuenta no tiene VPC default (se pudo haber borrado), este data source falla:
# hay que crear una VPC propia o restaurar la default antes del apply.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "bucket" {
  source = "../modules/s3"

  bucket_name = var.bucket_name
  environment = var.environment
  tags        = local.common_tags

  upload_object       = true
  object_key          = "index.html"
  object_source       = "${path.module}/index.html"
  object_content_type = "text/html"
}

module "notifier" {
  source = "../modules/lambda"

  function_name = var.function_name
  description   = "Se ejecuta cuando se sube un archivo al bucket ${var.bucket_name}"
  source_dir    = "${path.module}/src"
  tags          = local.common_tags

  environment_variables = {
    BUCKET_NAME = module.bucket.bucket_name
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.notifier.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.bucket.bucket_arn
}

resource "aws_s3_bucket_notification" "this" {
  bucket = module.bucket.bucket_id

  lambda_function {
    lambda_function_arn = module.notifier.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

module "ecs_app" {
  source = "../modules/ecs"

  app_name    = var.ecs_app_name
  environment = var.environment
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = data.aws_subnets.default.ids
  image_tag   = var.ecs_image_tag
  tags        = local.common_tags
}
