data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_s3_access" {
  statement {
    sid     = "DocstorePut"
    actions = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:GetObjectAcl"]
    resources = [
      "${aws_s3_bucket.docstore.arn}/*"
    ]
  }

  statement {
    sid       = "ListDocstore"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.docstore.arn]
  }
}

resource "aws_iam_role" "ec2" {
  name               = "pgp-searchengine-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  description        = "Instance role for uploader EC2"
}

resource "aws_iam_role_policy" "ec2_s3" {
  name   = "pgp-searchengine-ec2-s3"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ec2_s3_access.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "pgp-searchengine-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "ec2" {
  name        = "pgp-ec2-sg"
  description = "Allow SSH access to uploader EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "pgp-search-ec2-sg"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "uploader" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = local.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.ec2_key_name
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    if command -v dnf >/dev/null 2>&1; then sudo dnf install -y curl jq; else sudo yum install -y curl jq; fi
    ENDPOINT="${aws_opensearch_domain.dev.endpoint}"
    USERNAME="${var.os_master_user}"
    PASSWORD="${var.os_master_password}"
    ROLE_ARN="${aws_iam_role.lambda_exec.arn}"

    # wait a bit for domain to accept connections
      for i in $(seq 1 30); do
        STATUS=$(curl -sk -u "$USERNAME:$PASSWORD" -D - -o /dev/null "https://$ENDPOINT/_cluster/health" | head -n1 | awk '{print $2}' || true)
        if [ "$STATUS" = "200" ]; then
          echo "OpenSearch reachable (status=$STATUS)"
          break
        fi
        echo "Waiting for OpenSearch... (status=$STATUS)"
        sleep 10
      done

    # map IAM role to all_access for test purposes
      curl -sk -u "$USERNAME:$PASSWORD" \
        -H 'Content-Type: application/json' \
        -X PUT "https://$ENDPOINT/_plugins/_security/api/rolesmapping/all_access" \
        -d "{\"backend_roles\":[\"$ROLE_ARN\"]}"
  EOT

  tags = merge(var.default_tags, {
    Name = "pgp-search-uploader"
  })

  depends_on = [aws_opensearch_domain.dev]
}
