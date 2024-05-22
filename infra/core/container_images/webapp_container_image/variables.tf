variable "container_registry" {
  description = "The login server of the container registry"
  type        = string
}

variable "container_registry_admin_username" {
  description = "The admin username of the container registry"
  type        = string
}

variable "container_registry_admin_password" {
  description = "The admin password of the container registry"
  type        = string
}

variable "container_name" {
  description = "The name of the Docker container"
  type        = string
}

variable "resource_group_name" {
  description = "This is the name of an existing resource group to deploy to"
}

variable "location" {
  description = "This is the region of an existing resource group you want to deploy to"
}

variable "image_tag_filename" {
  type        = string
  description = "The tag of the image in the Container Registry"
}

variable "tags" {
  default = {}
}

variable "random_string" {
  description = "This is the random string that is used in the main deploy, we pass it in to keep consistent"
}