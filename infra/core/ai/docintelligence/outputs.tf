output "docintelligence_container_id" {
  value       = docker_container.docintelligence.id
  description = "The ID of the Docker container running Tesseract for Document Intelligence"
}

output "docintelligence_container_endpoint" {
  value       = "http://${docker_container.docintelligence.name}:${docker_container.docintelligence.ports[0].external}"
  description = "The endpoint of the Docker container running Tesseract for Document Intelligence"
}
