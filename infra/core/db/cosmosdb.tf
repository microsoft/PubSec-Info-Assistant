# Copyright (c) DataReason.
### Code for On-Premises Deployment.

provider "postgresql" {
  host     = var.postgresql_host
  port     = var.postgresql_port
  username = var.postgresql_username
  password = var.postgresql_password
  database = var.postgresql_database
  sslmode  = "disable"
}

resource "postgresql_database" "log_database" {
  name = var.log_database_name
}

resource "postgresql_schema" "log_schema" {
  name     = var.log_schema_name
  database = postgresql_database.log_database.name
}

resource "postgresql_table" "log_table" {
  name     = var.log_table_name
  schema   = postgresql_schema.log_schema.name
  database = postgresql_database.log_database.name
  owner    = var.postgresql_username

  definition = <<-EOT
  CREATE TABLE ${var.log_table_name} (
    id SERIAL PRIMARY KEY,
    file_name TEXT NOT NULL,
    state TEXT NOT NULL,
    state_timestamp TIMESTAMP NOT NULL,
    status_updates JSONB
  );
  EOT
}