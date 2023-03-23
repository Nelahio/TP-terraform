terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
  backend "azurerm" {
    
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
}

resource "azurerm_mssql_server" "sql-srv" {
  name                         = "sqlsrv-${var.project_name}${var.environment_suffix}"
  resource_group_name          = data.azurerm_resource_group.rg-maalsi.name
  location                     = data.azurerm_resource_group.rg-maalsi.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.database-login.value
  administrator_login_password = data.azurerm_key_vault_secret.database-password.value
}

# Database
resource "azurerm_mssql_database" "sql-db" {
  name           = "RabbitMqDemo"
  server_id      = azurerm_mssql_server.sql-srv.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false
}

#Web App
resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "web-app" {
  name                = "web-app-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = azurerm_service_plan.app-plan.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
  }

  connection_string {
    name = "DefaultConnection"
    value = "Server=tcp:${azurerm_mssql_server.sql-srv.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql-db.name};Persist Security Info=False;User ID=${data.azurerm_key_vault_secret.database-login.value};Password=${data.azurerm_key_vault_secret.database-password.value};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    type = "SQLAzure"
  }

  app_settings = {
    "RabbitMQ__Hostname" = azurerm_container_group.rabbitmq.fqdn,
    "RabbitMQ__Username" = data.azurerm_key_vault_secret.rabbitmq-login.value,
    "RabbitMQ__Password" = data.azurerm_key_vault_secret.rabbitmq-password.value
  }
}

#RabbitMQ Container Instance
resource "azurerm_container_group" "rabbitmq" {
  name                = "aci-mq-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  ip_address_type     = "Public"
  dns_name_label      = "aci-mq-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "rabbitmq"
    image  = "rabbitmq:3-management"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5672
      protocol = "TCP"
    }

    ports {
      port     = 15672
      protocol = "TCP"
    }

    environment_variables = {
      "RABBITMQ_DEFAULT_USER" = data.azurerm_key_vault_secret.rabbitmq-login.value,
      "RABBITMQ_DEFAULT_PASS" = data.azurerm_key_vault_secret.rabbitmq-password.value
    }
  }
}