# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "container_registry_config_file" {
  value = local_file.container_registry_config.filename
}

output "container_registry_key_file" {
  value = local_file.container_registry_key.filename
}