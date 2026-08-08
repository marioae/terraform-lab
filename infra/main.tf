locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "s3-lambda"
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
