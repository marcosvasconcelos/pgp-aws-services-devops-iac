resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, {
    Name = "pgp-search-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, {
    Name = "pgp-search-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.default_tags, {
    Name = "pgp-search-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.default_tags, {
    Name = "pgp-search-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  domain    = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.default_tags, {
    Name = "pgp-search-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  connectivity_type = "public"

  tags = merge(var.default_tags, {
    Name = "pgp-search-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.default_tags, {
    Name = "pgp-search-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.default_tags, {
    Name = "pgp-search-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(var.default_tags, {
    Name = "pgp-search-s3-endpoint"
  })
}

# Security group for OpenSearch (ingress only from Lambda SG)
resource "aws_security_group" "opensearch_sg" {
  name        = "pgp-os-sg"
  description = "Allow HTTPS from Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "pgp-os-sg"
  })
}

# Security group for Lambdas (egress -> OpenSearch)
resource "aws_security_group" "lambda_sg" {
  name        = "pgp-lambda-sg"
  description = "Lambda egress to OpenSearch"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.opensearch_sg.id]
    description     = "To OpenSearch"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "General egress"
  }

  tags = merge(var.default_tags, {
    Name = "pgp-lambda-sg"
  })
}

# Allow HTTPS ingress on OS from the Lambda SG
resource "aws_security_group_rule" "os_https_from_lambda" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
  description              = "Lambda to OpenSearch"
}

# Allow HTTPS ingress on OS from the EC2 SG (for admin curl/bootstrapping)
resource "aws_security_group_rule" "os_https_from_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch_sg.id
  source_security_group_id = aws_security_group.ec2.id
  description              = "EC2 to OpenSearch"
}
