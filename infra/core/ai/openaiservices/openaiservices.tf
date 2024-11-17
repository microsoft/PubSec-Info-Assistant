# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "local" {}

resource "local_file" "openai_services_config" {
  content = <<-EOT
  {
    "services": {
      "openai": {
        "provider": "huggingface",
        "config": {
          "model": "Llama-3.2-1B",
          "version": "1.0"
        }
      }
    }
  }
  EOT
  filename = "${path.module}/openai_services_config.json"
}

resource "local_file" "openai_services_key" {
  content = <<-EOT
  {
    "key": "${var.openai_services_key}"
  }
  EOT
  filename = "${path.module}/openai_services_key.json"
}