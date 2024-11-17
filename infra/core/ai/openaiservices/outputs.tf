# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "openai_services_config_file" {
  value = local_file.openai_services_config.filename
}

output "openai_services_key_file" {
  value = local_file.openai_services_key.filename
}