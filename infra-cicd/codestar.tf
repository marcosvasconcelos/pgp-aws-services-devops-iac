resource "aws_codestarconnections_connection" "github" {
  name          = "${local.name_prefix}-github-connection"
  provider_type = "GitHub"

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-github-connection"
    Description = "GitHub connection for CodePipeline"
  })
}

output "github_connection_arn" {
  description = "GitHub CodeStar connection ARN - activate in AWS console"
  value       = aws_codestarconnections_connection.github.arn
}

output "github_connection_status" {
  description = "GitHub CodeStar connection status"
  value       = aws_codestarconnections_connection.github.connection_status
}
