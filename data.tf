data "azurerm_resource_group" "rg-maalsi" {
  name = "rg-${var.project_name}${var.environment_suffix}"
}