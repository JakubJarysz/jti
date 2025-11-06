output "resource_group_name" {
  description = "Nazwa Resource Group"
  value       = azurerm_resource_group.main.name
}

output "web_app_name" {
  description = "Nazwa Web App"
  value       = azurerm_linux_web_app.main.name
}

output "web_app_url" {
  description = "URL Web App"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "web_app_swagger_url" {
  description = "URL Swagger UI"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}/swagger"
}

output "postgres_server_name" {
  description = "Nazwa PostgreSQL Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_fqdn" {
  description = "FQDN PostgreSQL Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Nazwa bazy danych"
  value       = azurerm_postgresql_flexible_server_database.main.name
}
output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main[0].instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main[0].connection_string
  sensitive   = true
}