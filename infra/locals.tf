data "aws_caller_identity" "me" {}

locals {
  account_id        = data.aws_caller_identity.me.account_id
  vpc_id            = aws_vpc.main.id

  # Bucket names (stable & unique)
  docstore_bucket   = coalesce(var.docstore_bucket_name,   "pgp-docstore-${local.account_id}")
  interm_bucket     = coalesce(var.intermediary_bucket_name, "pgp-intermediary-${local.account_id}")

  public_subnet_ids  = aws_subnet.public[*].id
  private_subnet_ids = aws_subnet.private[*].id
  os_subnets         = length(local.private_subnet_ids) > 0 ? [local.private_subnet_ids[0]] : []
}
