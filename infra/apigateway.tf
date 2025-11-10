resource "aws_apigatewayv2_api" "search" {
  name          = "pgp-search-http"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "gateway_lambda" {
  api_id                 = aws_apigatewayv2_api.search.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.gateway.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_integration" "search_lambda" {
  api_id                 = aws_apigatewayv2_api.search.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.search.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "search_any" {
  api_id    = aws_apigatewayv2_api.search.id
  route_key = "ANY /search"
  target    = "integrations/${aws_apigatewayv2_integration.search_lambda.id}"
}

resource "aws_apigatewayv2_route" "root_get" {
  api_id    = aws_apigatewayv2_api.search.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.gateway_lambda.id}"
}

resource "aws_apigatewayv2_stage" "search" {
  api_id      = aws_apigatewayv2_api.search.id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gateway.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.search.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigateway_invoke_search" {
  statement_id  = "AllowAPIGatewayInvokeSearch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.search.execution_arn}/*/*"
}

output "api_base_url" {
  value       = aws_apigatewayv2_api.search.api_endpoint
  description = "Base URL of the HTTP API ($default stage)"
}

output "api_search_url" {
  value       = "${aws_apigatewayv2_api.search.api_endpoint}/search"
  description = "ANY /search endpoint URL"
}
