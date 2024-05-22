output "image_tag" {
  value = data.local_file.image_tag.content
}

output "webapp_image_name" {
  value = "${var.container_registry}/webapp_container_image:${data.local_file.image_tag.content}"
}