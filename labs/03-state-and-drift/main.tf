terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "notes" {
  filename = "${path.module}/notes.txt"
  content  = "This file is managed by Terraform.\n"
}
