#Required Variables
variable "apim_name" {
  type        = string
  description = "The name of the Azure API Management resource"
}

variable "apim_resource_group_name" {
  type        = string
  description = "The name of the resource group containing the Azure API management resource"
}

#Optional Variables
variable "prefix" {
  type        = list(string)
  description = "A naming prefix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "suffix" {
  type        = list(string)
  description = "A naming suffix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "users" {
  type = set(object({
    user_id    = string
    first_name = string
    last_name  = string
    email      = string
    state      = string
  }))
  description = "Set of Azure API Management users"
  default     = []
}

variable "subscriptions" {
  type = list(object({
    user_id      = string
    product_id   = string
    display_name = string
  }))
  description = "Set of Azure API Management subscriptions"
  default     = []
}

variable "groups" {
  type = set(object({
    name         = string
    display_name = string
    description  = string
  }))
  description = "Set of Azure API Management groups"
  default = []
}

variable "group_users" {
  type = list(object({
    user_id = string
    group_name = string
  }))
  description = "group assignments for Azure API Management users"
  default = []
}

variable "module_depends_on" {
  default = [""]
}