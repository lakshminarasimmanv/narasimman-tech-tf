terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.29.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.21.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.2"
    }
  }
}

### AWS
provider "aws" {
}

### Cloudflare
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

### Random
provider "random" {
}