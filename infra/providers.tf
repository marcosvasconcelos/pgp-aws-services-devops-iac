provider "aws" {
  profile = var.profile
  region  = var.region

  default_tags {
    tags = merge(
      var.default_tags,
      {
        ManagedBy = "Terraform"
      }
    )
  }
}
