resource "docker_container" "docintelligence" {
  name  = "tesseract"
  image = "tesseractshadow/tesseract4re"

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = "/path/to/local/data"
    container_path = "/data"
  }

  env {
    TESSDATA_PREFIX = "/usr/share/tesseract-ocr/4.00/tessdata"
  }
}

resource "docker_network" "docintelligence_network" {
  name = "docintelligence_network"
}

resource "docker_volume" "docintelligence_volume" {
  name = "docintelligence_volume"
}
