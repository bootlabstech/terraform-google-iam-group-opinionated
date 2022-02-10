variable "groups" {
  description = "List of custom group definitions (refer to variables file for syntax). display_name_postfix will be used like this <group_prefix>-<display_name_postfix>"
  default     = []
  type = list(object({
    display_name_postfix = string
    initial_group_config = string
    description          = string
    folder_roles         = list(string)
  }))
}

variable "folder" {
  type        = string
  description = "The name of the Folder in the form {folder_id} or folders/{folder_id}"
}

variable "group_prefix" {
  type        = string
  description = "this prefix will be used like this <group_prefix>-Viewer"
}

variable "domain" {
  type        = string
  description = "Domain of the organization to create the group in."
}