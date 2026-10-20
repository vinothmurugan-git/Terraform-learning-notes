terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "environment" {
  description = "Name of the environment, for example dev or prod"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "server_count" {
  description = "Number of servers the application needs"
  type        = number
  default     = 1
}

resource "local_file" "config" {
  filename = "${path.module}/${var.environment}-config.txt"
  content  = <<-EOT
    App:         ${var.app_name}
    Environment: ${var.environment}
    Servers:     ${var.server_count}
  EOT
}

output "config_file" {
  description = "Path of the generated config file"
  value       = local_file.config.filename
}

output "summary" {
  description = "One-line summary of the configuration"
  value       = "${var.app_name} runs ${var.server_count} server(s) in ${var.environment}"
}
