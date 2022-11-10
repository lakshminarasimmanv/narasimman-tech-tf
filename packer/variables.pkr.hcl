variable "ami_version" {
  description = "Version of the custom AMI"
  type        = string
  default     = "latest"
}

variable "username" {
  description = "Username for the SSH user"
  type        = string
  default     = "ubuntu"
}

variable "build_name" {
  description = "Name of the build"
  type        = string
  default     = ""
}

variable "subnet" {
  description = "ID of the subnet"
  type        = string
  default     = ""
}

variable "instance" {
  description = "Type of the instance"
  type        = string
  default     = "t2.micro"
}


variable "region" {
  description = "Region to build the image"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name of the custom AMI"
  type        = string
  default     = ""
}

variable "env" {
  description = "Usage Environment"
  type        = string
  default     = "dev"
}

variable "ubuntu_version" {
  description = "Ubuntu Version"
  type        = string
  default     = "jammy-22.04"
}

variable "ami_description" {
  description = "Description of the AMI"
  type        = string
  default     = ""
}
