# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "local" {}

resource "local_file" "container_registry_config" {
  content = <<-EOT
  {
    "services": {
      "container_registry": {
        "provider": "docker_registry",
        "config": {
          "version": "2"
        }
      }
    }
  }
  EOT
  filename = "${path.module}/container_registry_config.json"
}

resource "local_file" "container_registry_key" {
  content = <<-EOT
  {
    "key": "${var.container_registry_key}"
  }
  EOT
  filename = "${path.module}/container_registry_key.json"
}