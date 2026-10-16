resource "github_repository_ruleset" "main" {
  for_each = github_repository.repositories

  name        = "protect-main"
  repository  = each.value.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 0

      dismiss_stale_reviews_on_push     = false
      require_last_push_approval        = false
      required_review_thread_resolution = false

      allowed_merge_methods = [
        "squash"
      ]
    }
  }
}
