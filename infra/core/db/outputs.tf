# Copyright (c) DataReason.
### Code for On-Premises Deployment.

output "postgresql_log_database_name" {
  value = postgresql_database.log_database.name
}

output "postgresql_log_schema_name" {
  value = postgresql_schema.log_schema.name
}

output "postgresql_log_table_name" {
  value = postgresql_table.log_table.name
}