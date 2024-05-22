output "image_tag" {
  value = data.local_file.image_tag.content
}

output "enrichment_image_name" {
  value = "${var.container_registry}/enrichment_container_image:${data.local_file.image_tag.content}"
}