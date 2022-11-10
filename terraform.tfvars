default_region          = "ap-south-1"
name                    = "NarasimmanTech"
cidr                    = "10.1.0.0/16"
azs                     = ["ap-south-1a", "ap-south-1b"]
public_subnets          = ["10.1.1.0/24", "10.1.3.0/24"]
private_subnets         = ["10.1.2.0/24", "10.1.4.0/24"]
rds_alloc_storage       = "10"
rds_max_storage         = "50"
rds_instance            = "db.t3.micro"