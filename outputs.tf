output "instance_public_ip" {
  value = aws_eip_association.eip_assoc.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.rds_mysql_db.endpoint
}
