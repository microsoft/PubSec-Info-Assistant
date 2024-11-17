# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "cog_services_config_file" {
  value = local_file.cog_services_config.filename
}

output "cog_services_key_file" {
  value = local_file.cog_services_key.filename
}