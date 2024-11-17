# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "doc_intelligence_config_file" {
  value = local_file.doc_intelligence_config.filename
}

output "doc_intelligence_key_file" {
  value = local_file.doc_intelligence_key.filename
}