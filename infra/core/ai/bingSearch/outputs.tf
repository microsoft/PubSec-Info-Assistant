# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "bing_search_index_name" {
  value = elasticsearch_index.bing_search.name
}

output "bing_search_key_index_name" {
  value = elasticsearch_index.bing_search_key.name
}