locals {
  direct_collaborators = {
    "ing-kelvin-castillo-umg" = {
      permission = "pull"
    }
  }

  repository_collaborators = {
    for pair in setproduct(
      keys(local.repositories),
      keys(local.direct_collaborators)
    ) :
    "${pair[0]}-${pair[1]}" => {
      repository_key = pair[0]
      username       = pair[1]
      permission     = local.direct_collaborators[pair[1]].permission
    }
  }
}

resource "github_repository_collaborator" "collaborators" {
  for_each = local.repository_collaborators

  repository = github_repository.repositories[each.value.repository_key].name
  username   = each.value.username
  permission = each.value.permission
}
