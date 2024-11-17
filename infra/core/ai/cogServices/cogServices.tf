# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "local" {}

resource "local_file" "cog_services_config" {
  content = <<-EOT
  {
    "services": {
      "computer_vision": {
        "provider": "opencv",
        "config": {
          "version": "4.5.3"
        }
      },
      "text_analytics": {
        "provider": "spacy",
        "config": {
          "model": "en_core_web_sm"
        }
      }
    }
  }
  EOT
  filename = "${path.module}/cog_services_config.json"
}

resource "local_file" "cog_services_key" {
  content = <<-EOT
  {
    "key": "${var.cog_services_key}"
  }
  EOT
  filename = "${path.module}/cog_services_key.json"
}
#Explanation:
#Local Provider: Used to create local configuration files for OpenCV and spaCy.
#Computer Vision: Configured to use OpenCV.
#Text Analytics: Configured to use spaCy.
#Configuration Files: Created local JSON files to store the configuration and key for cognitive services.
#These conversions provide on-premises equivalents for the original Azure Cognitive Services using OpenCV and spaCy. 