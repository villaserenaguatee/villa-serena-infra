locals {
  teams = {
    frontend = {
      description = "Frontend development team"
      members     = ["alexanderCanon", "Kym-22"]
    }

    backend = {
      description = "Backend development team"
      members     = ["Reyes209c", "ppalaciosm-cyber", "hugoat003"]
    }

    documentation = {
      description = "Documentation team"
      members     = ["Josssueee"]
    }

    infrastructure = {
      description = "Infrastructure and DevOps team"
      members     = ["Josssueee"]
    }
  }

  # Flatten teams and members for github_team_membership
  team_members = merge([
    for team_key, team in local.teams : {
      for member in team.members :
      "${team_key}-${member}" => {
        team_key = team_key
        username = member
      }
    }
  ]...)

  # Flatten teams and repositories for github_team_repository
  team_repositories = {
    for pair in setproduct(keys(local.teams), keys(local.repositories)) :
    "${pair[0]}-${pair[1]}" => {
      team_key       = pair[0]
      repository_key = pair[1]
    }
  }
}

resource "github_team" "teams" {
  for_each = local.teams

  name        = each.key
  description = each.value.description
  privacy     = "closed"
}

resource "github_team_membership" "members" {
  for_each = local.team_members

  team_id  = github_team.teams[each.value.team_key].id
  username = each.value.username
  role     = "member"
}

resource "github_team_repository" "team_repositories" {
  for_each = local.team_repositories

  team_id    = github_team.teams[each.value.team_key].id
  repository = github_repository.repositories[each.value.repository_key].name
  permission = "admin"
}
