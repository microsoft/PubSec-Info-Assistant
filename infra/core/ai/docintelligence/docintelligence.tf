# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "local" {}

resource "local_file" "doc_intelligence_config" {
  content = <<-EOT
  {
    "services": {
      "form_recognizer": {
        "provider": "tesseract",
        "config": {
          "version": "4.1.1"
        }
      }
    }
  }
  EOT
  filename = "${path.module}/doc_intelligence_config.json"
}

resource "local_file" "doc_intelligence_key" {
  content = <<-EOT
  {
    "key": "${var.doc_intelligence_key}"
  }
  EOT
  filename = "${path.module}/doc_intelligence_key.json"
}