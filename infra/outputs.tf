output "docstore_bucket"     { value = aws_s3_bucket.docstore.bucket }
output "intermediate_bucket" { value = aws_s3_bucket.intermediate.bucket }
output "lambda_names" {
  value = {
    pdftotxt = aws_lambda_function.pdftotxt.function_name
    upload   = aws_lambda_function.upload.function_name
    gateway  = aws_lambda_function.gateway.function_name
    search   = aws_lambda_function.search.function_name
  }
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.search.invoke_url
}

output "uploader_ec2_public_ip" {
  value = aws_instance.uploader.public_ip
}
