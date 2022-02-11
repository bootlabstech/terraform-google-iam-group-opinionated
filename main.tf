data "google_organization" "org" {
  domain = var.domain
}

locals {
  # don't change the type unless you understand it completely
  type        = "default"
  label_keys = {
    "default" = "cloudidentity.googleapis.com/groups.discussion_forum"
    # Placeholders according to https://cloud.google.com/identity/docs/groups#group_properties.
    # Not supported by provider yet.
    "dynamic"  = "cloudidentity.googleapis.com/groups.dynamic"
    "security" = "cloudidentity.googleapis.com/groups.security"
    "external" = "system/groups/external"
  }

  folder_binding = var.folder != null ? flatten([
    for g in var.groups : [
      for r in g.folder_roles : {
        id = "${var.group_prefix}-${g.display_name_postfix}@${var.domain}|${r}"
        group_id = "${var.group_prefix}-${g.display_name_postfix}@${var.domain}"
        role = r
      }
    ]
  ]) : []

  org_binding = var.folder == null ? flatten([
    for g in var.groups : [
      for r in g.folder_roles : {
        id = "${var.group_prefix}-${g.display_name_postfix}@${var.domain}|${r}"
        group_id = "${var.group_prefix}-${g.display_name_postfix}@${var.domain}"
        role = r
      }
    ]
  ]) : []
}

resource "google_cloud_identity_group" "cloud_identity_group_basic" {
  for_each             = { for x in var.groups : x.display_name_postfix => x }
  display_name         = "${var.group_prefix}-${each.value.display_name_postfix}"
  initial_group_config = each.value.initial_group_config
  parent               = "customers/${data.google_organization.org.directory_customer_id}"
  description          = each.value.description
  group_key {
    id = "${var.group_prefix}-${each.value.display_name_postfix}@${var.domain}"
  }
  labels = {
    local.label_keys[local.type] = ""
  }
}

data "google_folder" "folder" {
  count               = var.folder != null ? 1 : 0
  folder              = var.folder
} 

resource "google_folder_iam_member" "folder" {
  for_each    = { for f in local.folder_binding : f.id => f }
  folder      = data.google_folder.folder[0].name
  role        = each.value.role
  member      = each.value.group_id

  depends_on  = [
    google_cloud_identity_group.cloud_identity_group_basic
  ]
}

resource "google_organization_iam_member" "org" {
  for_each    = { for f in local.org_binding : f.id => f }
  org_id      = data.google_organization.org.org_id
  role        = each.value.role
  member      = each.value.group_id

  depends_on  = [
    google_cloud_identity_group.cloud_identity_group_basic
  ]
}