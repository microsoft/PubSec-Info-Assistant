# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "elasticsearch" {
  url = var.elasticsearch_url
}

resource "elasticsearch_index" "bing_search" {
  name = "bingsearch-${var.randomString}"
  settings = <<SETTINGS
{
  "index": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  }
}
SETTINGS
  mappings = <<MAPPINGS
{
  "properties": {
    "name": { "type": "text" },
    "location": { "type": "text" },
    "sku": { "type": "text" },
    "tags": { "type": "object" }
  }
}
MAPPINGS
}

resource "elasticsearch_index" "bing_search_key" {
  name = "bingsearch-key-${var.randomString}"
  settings = <<SETTINGS
{
  "index": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  }
}
SETTINGS
  mappings = <<MAPPINGS
{
  "properties": {
    "key": { "type": "text" }
  }
}
MAPPINGS
}
