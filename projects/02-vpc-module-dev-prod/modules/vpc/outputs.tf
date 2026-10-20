output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Map of availability zone to public subnet ID"
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}
