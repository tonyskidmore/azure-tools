variable "resource_group_name" {
  description = "(Required) The name of the resource group."
  type        = string
}

variable "resource_group_location" {
  description = "(Required) The location of the resource group where to create the resource."
  type        = string
}

variable "tags" {
  description = "(Required) Map of tags to be applied to the resource"
  type        = map(any)
  default     = {}
}
