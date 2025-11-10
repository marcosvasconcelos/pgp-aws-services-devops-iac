resource "aws_s3_bucket" "docstore" {
  bucket        = local.docstore_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "intermediate" {
  bucket        = local.interm_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_all" {
  for_each = {
    docstore     = aws_s3_bucket.docstore.id
    intermediate = aws_s3_bucket.intermediate.id
  }
  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
