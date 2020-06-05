provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "naming" {
  source = "git@github.com:Azure/terraform-azurerm-naming"
}

resource "azurerm_resource_group" "test_group" {
  name     = "${module.naming.resource_group.slug}-${module.naming.api_management.slug}-user-max-test-${substr(module.naming.unique-seed, 0, 5)}"
  location = "uksouth"
}

resource "azurerm_api_management" "apim" {
  name                = module.naming.api_management.name_unique
  location            = azurerm_resource_group.test_group.location
  resource_group_name = azurerm_resource_group.test_group.name
  publisher_name      = "John Doe"
  publisher_email     = "john@doe.com"

  sku_name = "Developer_1"
}

resource "azurerm_api_management_product" "apim" {
  product_id            = "myproductid"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.test_group.name
  display_name          = "My Product ID"
  subscription_required = true
  subscriptions_limit   = 1
  approval_required     = true
  published             = true
}

resource "azurerm_api_management_api" "apim" {
  name                = "myapi"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.test_group.name
  revision            = "1"
  display_name        = "My API"
  path                = "api"
  protocols           = ["http"]
  service_url         = "https://google.com"
}

resource "azurerm_api_management_product_api" "apim" {
  api_name            = azurerm_api_management_api.apim.name
  product_id          = azurerm_api_management_product.apim.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.test_group.name
}

module "apim_users" {
  source = "../../"

  apim_name                = azurerm_api_management.apim.name
  apim_resource_group_name = azurerm_resource_group.test_group.name

  # API Management Users
  users = [{
    user_id    = "alice"
    first_name = "alice"
    last_name  = "doe"
    email      = "alice@doe.com"
    state      = "active"
  }]

  # API Management Subscriptions
  subscriptions = [{
    user_id      = "alice"
    product_id   = "myproductid"
    display_name = "myapi subscription"
  }]

  # API Management Groups
  groups = [{
    name         = "mygroup"
    display_name = "My Group"
    description  = "My group"
  }]

  # API Management Group Users
  group_users = [{
    user_id    = "alice"
    group_name = "mygroup"
  }]

  module_depends_on = [azurerm_api_management_product_api.apim]
}
