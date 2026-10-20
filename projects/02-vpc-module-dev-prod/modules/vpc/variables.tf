variable "name" {
  description = "Name used for the VPC and its resources, for example dev or prod"
  type        = string
}

variable "vpc_cidr" {
  description = "IP address range for the VPC, for example 10.0.0.0/16"
  type        = string
}

variable "public_subnets" {
  description = "Map of availability zone to subnet IP range"
  type        = map(string)
}
