data "local_file" "image_tag" {
  filename = var.image_tag_filename
}

locals {
  sanitised_container_name    = replace(var.container_name, "_", "")
  stripped_container_registry = replace(var.container_registry, "https://", "")
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<-EOT
        printf "%s" ${var.container_registry_admin_password} | docker login --username ${var.container_registry_admin_username} --password-stdin ${var.container_registry}
        docker tag function_container_image ${local.stripped_container_registry}/function_container_image:${data.local_file.image_tag.content}
        docker push ${local.stripped_container_registry}/function_container_image:${data.local_file.image_tag.content}
      EOT
  }
  triggers = {
    always_run = timestamp()
  }
}