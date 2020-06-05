provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "naming" {
  source = "git@github.com:Azure/terraform-azurerm-naming"
  suffix = var.suffix
  prefix = var.prefix
}

resource "null_resource" "module_depends_on" {
  triggers = {
    value = "${length(var.module_depends_on)}"
  }
}

resource "azurerm_api_management_user" "apim" {
  for_each = { for user in var.users : user.user_id => user }

  user_id             = each.value.user_id
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.base.name
  first_name          = each.value.first_name
  last_name           = each.value.last_name
  email               = each.value.email
  state               = each.value.state

  depends_on = [null_resource.module_depends_on]
}

data "azurerm_api_management_user" "subscriptions" {
  count = length(var.subscriptions)

  user_id             = azurerm_api_management_user.apim[var.subscriptions[count.index].user_id].user_id # force dep
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.base.name

  depends_on = [null_resource.module_depends_on]
}

data "azurerm_api_management_product" "subscriptions" {
  count = length(var.subscriptions)

  product_id          = var.subscriptions[count.index].product_id
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.base.name

  depends_on = [null_resource.module_depends_on]
}

data "null_data_source" "subscriptions" {
  count = length(var.subscriptions)

  inputs = {
    product_id = data.azurerm_api_management_product.subscriptions[count.index].id
    user_id    = data.azurerm_api_management_user.subscriptions[count.index].id
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [data.null_data_source.subscriptions]

  create_duration = "30s"
}

resource "azurerm_api_management_subscription" "apim" {
  count = length(var.subscriptions)

  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.base.name
  user_id             = data.null_data_source.subscriptions[count.index].outputs["user_id"]
  product_id          = data.null_data_source.subscriptions[count.index].outputs["product_id"]
  display_name        = var.subscriptions[count.index].display_name

  depends_on = [
    null_resource.module_depends_on,
    time_sleep.wait_30_seconds
  ]
}

resource "azurerm_api_management_group" "apim" {
  for_each = { for group in var.groups : group.name => group }

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.base.name
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = each.value.display_name
  description         = each.value.description

  depends_on = [null_resource.module_depends_on]
}

data "azurerm_api_management_group" "group_users" {
  count = length(var.group_users)

  name                = azurerm_api_management_group.apim[var.group_users[count.index].group_name].name # force dep
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.base.name
}

resource "azurerm_api_management_group_user" "group_users" {
  count = length(var.group_users)

  user_id             = var.group_users[count.index].user_id
  group_name          = data.azurerm_api_management_group.group_users[count.index].name
  resource_group_name = data.azurerm_resource_group.base.name
  api_management_name = data.azurerm_api_management.apim.name

  depends_on = [null_resource.module_depends_on]
}
