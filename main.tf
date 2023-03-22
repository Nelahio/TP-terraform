terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
}

resource "azurerm_resource_group" "rg-maalsi" {   
  name     = "rg-${var.project_name}${var.environment_suffix}"
  location = var.location
}

resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = azurerm_resource_group.rg-maalsi.name
  location            = azurerm_resource_group.rg-maalsi.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "web-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg-maalsi.name
  location            = azurerm_resource_group.rg-maalsi.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config {}
}