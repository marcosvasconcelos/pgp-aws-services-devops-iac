variable "profile" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "default_tags" {
  type = map(string)
  default = {
    Project = "PGP-SearchEngine"
    Env     = "dev"
  }
}

variable "os_master_user" {
  type        = string
  default     = "master-user"
  description = "OpenSearch master username (FGAC internal DB)"
}

variable "os_master_password" {
  type        = string
  sensitive   = true
  description = "OpenSearch master user password (set via tfvars or ENV TF_VAR_os_master_password)"
}

variable "docstore_bucket_name" {
  type        = string
  default     = null
  description = "If null, will autogenerate with account id"
}
variable "intermediary_bucket_name" {
  type        = string
  default     = null
  description = "If null, will autogenerate with account id"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "CIDR block for the dedicated VPC created for the search stack"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Availability zones used when creating subnets"

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "availability_zones must include at least one AZ"
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
  description = "CIDR blocks for public subnets (one per AZ)"

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "public_subnet_cidrs must have the same number of entries as availability_zones"
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
  description = "CIDR blocks for private subnets (one per AZ)"

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "private_subnet_cidrs must have the same number of entries as availability_zones"
  }
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the uploader EC2 instance"
}

variable "ec2_key_name" {
  type        = string
  default     = "my-key"
  description = "Optional EC2 key pair name for SSH access"
}

variable "allowed_ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block allowed to SSH into the uploader EC2 instance"
}

variable "dashboards_allowed_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks allowed to access the public OpenSearch endpoint (Dashboards and REST). Narrow this in production."
}

variable "admin_iam_user_arn" {
  type        = string
  default     = null
  description = "Optional IAM user ARN granted es:ESHttp* to manage OpenSearch security APIs (rolesmapping). If null, user access not added."
}
