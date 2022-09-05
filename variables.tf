variable "default_region" {
  description = "Default region"
  type        = string
}

variable "user_access_key" {
  description = "User Access Key"
  type        = string
  sensitive   = true
}

variable "user_secret_key" {
  description = "User Secret key"
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Project name"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "CIDR block range"
  type        = string
  default     = "0.0.0.0/0"
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnets"
  type        = list(string)
  default     = []
}

variable "bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "acl" {
  description = "S3 Bucket ACL"
  type        = string
  default     = "private"
}

variable "rds_alloc_storage" {
  description = "Allocated storage size for RDS instance"
  type        = string
  default     = ""
}

variable "rds_max_storage" {
  description = "Maximum storage size for RDS instance"
  type        = string
  default     = ""
}

variable "rds_instance" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_user" {
  description = "RDS Database Username"
  type        = string
  sensitive   = true
}

variable "db_pass" {
  description = "RDS Database Password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "RDS Database Name"
  type        = string
  sensitive   = true
}

variable "kms_alias" {
  description = "Key Management Store's alias name"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Type of EC2 Instance"
  type        = string
  default     = "t2.micro"
}

variable "instance_key" {
  description = "EC2 Instance ssh key"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-068257025f72f470d"
}

variable "elb_name" {
  description = "Elastic load balancer Name"
  type        = string
  default     = ""
}

variable "elb_type" {
  description = "Elastic load balancer type"
  type        = string
  default     = "application"
}

variable "elb_tg_name" {
  description = "Elastic load balancer target group name"
  type        = string
  default     = ""
}

variable "dynamodb_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = ""
}

variable "state_bucket_name" {
  description = "Terraform State File Bucket"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_key" {
  description = "Cloudflare Account API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Cloudflare Account Email ID"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = "narasimmantech.com"
}

variable "rds_snapshot_identifier" {
  description = "RDS(mysql) Manual Snapshot Identifier(arn)"
  type        = string
  sensitive   = true
  default     = ""
}