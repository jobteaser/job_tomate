require 'active_support/all'

module JobTomate
  class GithubProcessor

    # Perform a run where:
    #   - it takes parsed webhooks datas send by github in params,
    #   - defines params from the webhook in order to make a POST request on Jira,
    #   - set the correct comment considering the PR status.
    def self.run(webhook_data)
      branche = webhook_data['pull_request']['head']['ref']
      issue_key = branche[/jt-[\d]+/i]
      github_user = webhook_data['pull_request']['user']['login']
      user = JobTomate::User.where(github_user: github_user).first
      user ? [user.jira_username, user.jira_password] : nil
      if webhook_data['action'] == 'closed'
        comment = if webhook_data['pull_request']['merged']
                    "Merged PR in #{webhook_data['pull_request']['base']['ref']}"
                  else
                    "PR closed but not merged"
                  end
      else
        comment = "Opened PR : #{webhook_data['pull_request']['html_url']}"
      end
      JobTomate::JiraClient.add_comment(issue_key, user.jira_username, user.jira_password, comment)
    end
  end
end