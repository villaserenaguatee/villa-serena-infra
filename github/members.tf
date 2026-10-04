locals {
  org_admins = [
    "alexanderCanon",
    "Kym-22",
    "Reyes209c",
    "Josssueee",
    "ppalaciosm-cyber",
    "hugoat003",
  ]

  org_members = [
    "ing-kelvin-castillo-umg",
  ]

  all_org_members = merge(
    { for u in local.org_admins : u => "admin" },
    { for u in local.org_members : u => "member" }
  )
}

resource "github_membership" "members" {
  for_each = local.all_org_members

  username = each.key
  role     = each.value
}
