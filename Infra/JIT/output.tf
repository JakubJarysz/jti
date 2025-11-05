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

output "deployment_commands" {
  description = "Komendy do deploymentu aplikacji"
  value = <<-EOT
  
  ========================================
  NASTĘPNE KROKI PO TERRAFORM APPLY
  ========================================
  
  1. Zbuduj i wypchnij obraz Docker do ACR:
     az acr login --name ${azurerm_container_registry.main.name}
     docker build -t ${azurerm_container_registry.main.login_server}/flask-app:latest .
     docker push ${azurerm_container_registry.main.login_server}/flask-app:latest
  
  2. Zaktualizuj Web App z nowym obrazem:
     az webapp config container set \
       --name ${azurerm_linux_web_app.main.name} \
       --resource-group ${azurerm_resource_group.main.name} \
       --docker-custom-image-name ${azurerm_container_registry.main.login_server}/flask-app:latest
  
  3. Skonfiguruj uprawnienia PostgreSQL (połącz się jako admin):
     psql "host=${azurerm_postgresql_flexible_server.main.fqdn} port=5432 dbname=${azurerm_postgresql_flexible_server_database.main.name} user=${azurerm_postgresql_flexible_server.main.administrator_login} sslmode=require"
     
     Wykonaj SQL:
     SET aad_validate_oids_in_tenant = off;
     CREATE ROLE "${azurerm_user_assigned_identity.app.name}" WITH LOGIN PASSWORD NULL IN ROLE azure_ad_user;
     GRANT CONNECT ON DATABASE ${azurerm_postgresql_flexible_server_database.main.name} TO "${azurerm_user_assigned_identity.app.name}";
     GRANT USAGE ON SCHEMA public TO "${azurerm_user_assigned_identity.app.name}";
     GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "${azurerm_user_assigned_identity.app.name}";
     GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "${azurerm_user_assigned_identity.app.name}";
     ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "${azurerm_user_assigned_identity.app.name}";
     ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "${azurerm_user_assigned_identity.app.name}";
  
  4. Restart Web App:
     az webapp restart \
       --name ${azurerm_linux_web_app.main.name} \
       --resource-group ${azurerm_resource_group.main.name}
  
  5. Sprawdź aplikację:
     Web App: https://${azurerm_linux_web_app.main.default_hostname}
     Swagger: https://${azurerm_linux_web_app.main.default_hostname}/swagger
     Health:  https://${azurerm_linux_web_app.main.default_hostname}/health
  
  6. Monitoruj logi:
     az webapp log tail \
       --name ${azurerm_linux_web_app.main.name} \
       --resource-group ${azurerm_resource_group.main.name}
  
  ========================================
  EOT
}