## Data Sources
data "aws_cloudfront_origin_access_identity" "oai" {
  id = "EET1GZDUV9TKI"
}

# ---------------------------------------
## Random pet name generator
resource "random_pet" "name" {
  length = 1
}

# ---------------------------------------
## VPC Configuration
module "vpc" {
  source = "github.com/lakshminarasimmanv/terraform-aws-vpc-module"

  cidr            = var.cidr
  name            = "${var.name}-VPC"
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# ---------------------------------------
## S3 Configuration
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id

  acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = file("bucket_policy.json")
}

# ---------------------------------------
## RDS Configuration
resource "aws_db_instance" "rds_mysql_db" {
  allocated_storage        = var.rds_alloc_storage
  max_allocated_storage    = var.rds_max_storage
  engine                   = "mysql"
  instance_class           = var.rds_instance
  db_name                  = var.db_name
  username                 = var.db_user
  password                 = var.db_pass
  snapshot_identifier      = var.rds_snapshot_identifier
  skip_final_snapshot      = true
  delete_automated_backups = true
  publicly_accessible      = false
  db_subnet_group_name     = aws_db_subnet_group.rds_mysql_db_sg.id
  vpc_security_group_ids   = [module.vpc.sg_allow_rds_mysql]
  availability_zone        = var.azs[0]
  backup_retention_period  = 7
  backup_window            = "06:30-07:00"
  maintenance_window       = "Sun:05:00-Sun:05:30"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [snapshot_identifier]
  }
}

## DB Subnet Group
resource "aws_db_subnet_group" "rds_mysql_db_sg" {
  name       = "rds_mysql_db_sg"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
}

# ---------------------------------------
## Key Management Service
resource "aws_kms_key" "a" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
  multi_region            = true
  policy                  = file("./key-policy.json")

  tags = {
    "Env" = "Prod"
  }
}

resource "aws_kms_alias" "a" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.a.key_id
}

# ---------------------------------------
## CloudFront Configuration
locals {
  s3_origin_id = "NarasimmanTechS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = data.aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
    Name        = "NarasimmanTech"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ---------------------------------------
# EC2 and Elastic IP Configuration
resource "aws_instance" "site" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.instance_key

  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    "${module.vpc.sg_allow_tls}",
    "${module.vpc.sg_allow_http}",
    "${module.vpc.sg_allow_ssh}",
    "${aws_security_group.allow_nfs.id}"
  ]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = "12"
    volume_type = "gp2"
  }

  tags = {
    Name = "NarasimmanTech"
  }
}

## Elastic IP
resource "aws_eip" "lb" {
  instance = aws_instance.site.id
  vpc      = true

  tags = {
    "Name" = "narasimmantech",
    "Env"  = "Prod"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.site.id
  allocation_id = aws_eip.lb.id
}

# ---------------------------------------
## Elastic Load Balancer

### Load Balancer Configuration
resource "aws_lb" "main" {
  name               = var.elb_name
  internal           = false
  load_balancer_type = var.elb_type
  security_groups    = [module.vpc.sg_allow_http, module.vpc.sg_allow_tls]
  subnets            = ["${module.vpc.public_subnets[0]}", "${module.vpc.public_subnets[1]}"]

  tags = {
    Env = "production"

    Usage = "Narasimman Tech"
  }
}

### Target Group Configuration
resource "aws_lb_target_group" "main" {
  name     = var.elb_tg_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

### Target Group Attachment
resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.site.id
  port             = 80
}

### Target Group Listener
#### Redirect 80 ---> 443
resource "aws_lb_listener" "listerner_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#### Listening on 443
resource "aws_lb_listener" "listerner_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

### Listener Certificate Configuration
# resource "aws_lb_listener_certificate" "cert" {
#   listener_arn    = aws_lb_listener.listerner_https.arn
#   certificate_arn = aws_acm_certificate.cert.arn
# }

# ---------------------------------------
## EFS File System

resource "aws_efs_file_system" "narasimmantech_efs" {
  availability_zone_name = aws_instance.site.availability_zone
  encrypted              = true

  tags = {
    Name = "Website Data and Theme"
  }
}

resource "aws_efs_mount_target" "alpha" {
  depends_on = [
    aws_efs_file_system.narasimmantech_efs
  ]
  file_system_id  = aws_efs_file_system.narasimmantech_efs.id
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = ["${aws_security_group.allow_nfs.id}"]
}

## EFS Security Group
resource "aws_security_group" "allow_nfs" {
  name        = "allow_nfs"
  description = "Allow EFS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "NFS from EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nfs"
  }
}

# ---------------------------------------
## Remote Statefile Configuration

### S3
resource "aws_s3_bucket" "narasimman-tech-statefile" {
  bucket = var.state_bucket_name

  tags = {
    Name        = "Narasimman Tech Statefile"
    Environment = "Prod"
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_s3_bucket_acl" "narasimman-tech-statefile-acl" {
  bucket = aws_s3_bucket.narasimman-tech-statefile.id
  acl    = var.acl
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = var.state_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_ss_encrypt" {
  bucket = aws_s3_bucket_versioning.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "narasimman-tech-tfstatefile-bucket-policy" {
  bucket = aws_s3_bucket.narasimman-tech-statefile.id
  policy = file("./s3-tfstate-policy.json")
}

### DynamoDB
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_policy" "db_policy" {
  name        = "dynamodb_policy"
  path        = "/"
  description = "My DynamoDB policy"

  policy = file("./dynamodb-policy.json")
}

# ---------------------------------------
## Simple Email Service

resource "aws_ses_domain_identity" "narasimman-tech-ses-domain-id" {
  domain = var.domain_name
}

resource "aws_ses_domain_identity_verification" "example_verification" {
  domain = aws_ses_domain_identity.narasimman-tech-ses-domain-id.id

  depends_on = [cloudflare_record.narasimman-tech-record]
}

resource "aws_ses_domain_identity" "example" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "example" {
  domain = aws_ses_domain_identity.example.domain
}

resource "aws_ses_domain_mail_from" "example" {
  domain           = aws_ses_domain_identity.example.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.example.domain}"
}

# ---------------------------------------
## AWS ACM Certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  validation_option {
    domain_name       = var.domain_name
    validation_domain = var.domain_name
  }

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------
## Cloudflare Configuration

# Update Domain IP
# resource "cloudflare_record" "narasimmantech_eip" {
#   zone_id = var.cloudflare_zone_id
#   name    = var.domain_name
#   value   = aws_eip.lb.public_ip
#   proxied = false
#   type    = "A"
# }

resource "cloudflare_record" "narasimmantech-lb" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  value   = aws_lb.main.dns_name
  type    = "CNAME"
}

resource "cloudflare_record" "narasimman-tech-record" {
  zone_id = var.cloudflare_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.narasimman-tech-ses-domain-id.id}"
  value   = aws_ses_domain_identity.narasimman-tech-ses-domain-id.verification_token
  type    = "TXT"
  ttl     = "600"
}

resource "cloudflare_record" "narasimman-tech-record-2" {
  count   = 3
  zone_id = var.cloudflare_zone_id
  name    = "${element(aws_ses_domain_dkim.example.dkim_tokens, count.index)}._domainkey"
  value   = "${element(aws_ses_domain_dkim.example.dkim_tokens, count.index)}.dkim.amazonses.com"
  type    = "CNAME"
  ttl     = "600"
}

resource "cloudflare_record" "narasimman-tech-record-3" {
  zone_id  = var.cloudflare_zone_id
  name     = aws_ses_domain_mail_from.example.mail_from_domain
  value    = "feedback-smtp.us-east-1.amazonses.com"
  priority = "10"
  type     = "MX"
  ttl      = "600"
}

resource "cloudflare_record" "narasimman-tech-record-4" {
  zone_id = var.cloudflare_zone_id
  name    = aws_ses_domain_mail_from.example.mail_from_domain
  value   = "v=spf1 include:amazonses.com -all"
  type    = "TXT"
  ttl     = "600"
}

resource "cloudflare_record" "domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.record
  type    = each.value.type

  depends_on = [
    aws_acm_certificate.cert
  ]
}