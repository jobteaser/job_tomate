require 'active_support/all'
require 'job_tomate/user'
require 'job_tomate/interface/jira_client'

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
      user = User.where(github_user: github_user).first
      user ? [user.jira_username, user.jira_password] : nil
      if webhook_data['action'] == 'closed'
        comment = if webhook_data['pull_request']['merged']
                    "Merged PR in #{webhook_data['pull_request']['base']['ref']} (via job_tomate)"
                  else
                    "PR closed but not merged (via job_tomate)"
                  end
      elsif webhook_data['action'] == 'opened'
        comment = "Opened PR : #{webhook_data['pull_request']['html_url']} (via job_tomate)"
      end
      JobTomate::Interface::JiraClient.add_comment(issue_key, user.jira_username, user.jira_password, comment)
    end
  end
end
