source "amazon-ebs" "ubuntu" {
  ami_description = var.ami_description
  ami_name        = "ami-${var.name}-${var.ami_version}"
  instance_type   = var.instance
  region          = var.region
  subnet_id       = var.subnet

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-${var.ubuntu_version}-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = var.username

  force_deregister      = true
  force_delete_snapshot = true

  tags = {
    Name = var.name,
    Env  = var.env
  }
}

build {
  name = var.build_name
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/docker.yml"
  }

  provisioner "ansible" {
    playbook_file = "../ansible/hashicorp.yml"
  }
}