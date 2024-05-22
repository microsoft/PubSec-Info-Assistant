output "image_tag" {
  value = data.local_file.image_tag.content
}

output "function_image_name" {
  value = "${var.container_registry}/function_container_image:${data.local_file.image_tag.content}"
}