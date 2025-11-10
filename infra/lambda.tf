locals {
  lambda_src = {
    pdftotxt = <<-PY
      import json, os
      def handler(event, context):
          print("pdftotxt triggered:", json.dumps(event))
          target = os.environ.get("TARGET_BUCKET")
          return {"status":"ok","target_bucket":target}
    PY
    upload = <<-PY
      import json, os
      def handler(event, context):
          print("upload-to-search triggered:", json.dumps(event))
          region = os.environ.get("REGION")
          host   = os.environ.get("OPENSEARCH_HOST")
          return {"status":"ok","region":region,"host":host}
    PY
    gateway = <<-PY
      import json
      def lambda_handler(event, context):
          print("search-gateway event:", json.dumps(event))
          return {"statusCode":200,"body":"OK gateway"}
    PY
    search = <<-PY
      import json, os
      def lambda_handler(event, context):
          print("searchFunction event:", json.dumps(event))
          region = os.environ.get("REGION")
          host   = os.environ.get("OPENSEARCH_HOST")
          return {"statusCode":200,"body":json.dumps({"region":region,"host":host})}
    PY
  }
}

data "archive_file" "pdftotxt_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/pdftotxt/lambda_function.py"
  output_path = "${path.module}/lambdas/pdftotxt/pdftotxt.zip"
}

data "archive_file" "upload_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/upload/lambda_function.py"
  output_path = "${path.module}/lambdas/upload/upload.zip"

}

data "archive_file" "gateway_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/gateway"
  output_path = "${path.module}/lambdas/gateway/gateway.zip"
  excludes    = ["gateway.zip"]

}

data "archive_file" "search_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/search/lambda_function.py"
  output_path = "${path.module}/lambdas/search/search.zip"
}

resource "aws_lambda_function" "pdftotxt" {
  function_name = "pgp-pdftotxt"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  filename      = data.archive_file.pdftotxt_zip.output_path
  timeout       = 30
  memory_size   = 256
  layers        = [
    "arn:aws:lambda:us-east-1:138312698703:layer:layer-pypdf:1",
    "arn:aws:lambda:us-east-1:138312698703:layer:pypdf-old:1"
  ]
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = local.os_subnets
  }
  environment {
    variables = {
      TARGET_BUCKET = aws_s3_bucket.intermediate.bucket
    }
  }
}

resource "aws_lambda_function" "upload" {
  function_name = "pgp-upload-to-search"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.upload_zip.output_path
  timeout       = 60
  memory_size   = 256
  layers        = ["arn:aws:lambda:us-east-1:138312698703:layer:aws_auth:1"]
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = local.os_subnets
  }
  environment {
    variables = {
      REGION          = var.region
      OPENSEARCH_HOST = aws_opensearch_domain.dev.endpoint
      OPENSEARCH_INDEX = "documents"
    }
  }
}
resource "aws_lambda_function" "gateway" {
  function_name = "pgp-search-gateway"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.gateway_zip.output_path
  timeout       = 30
  memory_size   = 256
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = local.os_subnets
  }
}

resource "aws_lambda_function" "search" {
  function_name = "pgp-search-function"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.search_zip.output_path
  timeout       = 60
  memory_size   = 256
  layers        = [
    "arn:aws:lambda:us-east-1:138312698703:layer:aws_auth:1",
    "arn:aws:lambda:us-east-1:138312698703:layer:pypdf-old:1"
  ]
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = local.os_subnets
  }
  environment {
    variables = {
      REGION          = var.region
      OPENSEARCH_HOST = aws_opensearch_domain.dev.endpoint
    }
  }
}

resource "aws_lambda_permission" "s3_invoke_pdftotxt" {
  statement_id  = "AllowS3InvokePdftotxt"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdftotxt.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.docstore.arn
}

resource "aws_lambda_permission" "s3_invoke_upload" {
  statement_id  = "AllowS3InvokeUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.intermediate.arn
}

resource "aws_s3_bucket_notification" "docstore_notify" {
  bucket = aws_s3_bucket.docstore.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.pdftotxt.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".pdf"
  }
  depends_on = [aws_lambda_permission.s3_invoke_pdftotxt]
}

resource "aws_s3_bucket_notification" "intermediate_notify" {
  bucket = aws_s3_bucket.intermediate.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.upload.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
  depends_on = [aws_lambda_permission.s3_invoke_upload]
}