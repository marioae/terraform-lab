resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name}-${random_id.bucket_suffix.hex}"

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_s3_object" "object" {
  count = var.upload_object ? 1 : 0

  bucket       = aws_s3_bucket.this.id
  key          = var.object_key
  source       = var.object_source
  content_type = var.object_content_type
  etag         = filemd5(var.object_source)
}
