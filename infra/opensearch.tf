data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "opensearch_access" {
  statement {
    sid     = "AllowLambdaExecHttp"
    effect  = "Allow"
    actions = ["es:ESHttp*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_exec.arn]
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev",
      "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev/*"
    ]
  }

  dynamic "statement" {
    for_each = var.admin_iam_user_arn == null ? [] : [var.admin_iam_user_arn]
    content {
      sid     = "AllowAdminUserHttp"
      effect  = "Allow"
      actions = ["es:ESHttp*"]

      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }

      resources = [
        "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev",
        "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev/*"
      ]
    }
  }

  # Allow internal FGAC basic-auth users (master-user, etc.) to pass resource policy gate.
  # Basic auth requests appear as anonymous at the resource policy layer; without this they are blocked
  # before the security plugin can validate credentials.
  statement {
    sid     = "AllowInternalBasicAuth"
    effect  = "Allow"
    actions = ["es:ESHttp*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev",
      "arn:${data.aws_partition.current.partition}:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/pgp-search-dev/*"
    ]
  }
}

resource "aws_opensearch_domain" "dev" {
  domain_name    = "pgp-search-dev"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
    volume_type = "gp3"
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch_sg.id]
    subnet_ids         = local.os_subnets
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.os_master_user
      master_user_password = var.os_master_password
    }
  }

  encrypt_at_rest         { enabled = true }
  node_to_node_encryption { enabled = true }
  domain_endpoint_options { enforce_https = true }

  access_policies = data.aws_iam_policy_document.opensearch_access.json

  lifecycle {
    ignore_changes = [advanced_security_options[0].master_user_options]
  }
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.dev.endpoint
}

output "opensearch_dashboards_url" {
  description = "Public URL for OpenSearch Dashboards"
  value       = "https://${aws_opensearch_domain.dev.endpoint}/_dashboards/"
}