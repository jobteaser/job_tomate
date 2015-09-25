require 'active_support/all'
require 'job_tomate/interface/jira_client'

module JobTomate

  # Processor for Github events triggered through webhook (see `webhooks_handler.rb`).
  class GithubProcessor

    # Perform a run where:
    #   - it takes parsed webhooks datas send by github in params,
    #   - defines params from the webhook in order to make a POST request on Jira,
    #   - set the correct comment considering the PR status.
    def self.run(webhook_data)
      add_jira_comment_on_pr_event(webhook_data)
    end

    # IMPLEMENTATION

    def self.add_jira_comment_on_pr_event(webhook_data)
      comment = jira_comment_on_pr_event(webhook_data)
      return if comment.nil?
      JobTomate::Interface::JiraClient.add_comment(
        issue_key(webhook_data),
        ENV['JIRA_USERNAME'], ENV['JIRA_PASSWORD'],
        comment)
    end

    def self.jira_comment_on_pr_event(webhook_data)
      if pr_action(webhook_data) == 'closed'
        if pr_merged?(webhook_data)
          return "Merged PR in #{pr_base_ref(webhook_data)}"
        end
        return 'PR closed but not merged'
      end
      if pr_action(webhook_data) == 'opened'
        return "Opened PR: #{pr_html_url(webhook_data)}"
      end
    end

    def self.issue_key(webhook_data)
      branch = webhook_data['pull_request']['head']['ref']
      branch[/jt-[\d]+/i]
    end

    def self.pr_action(webhook_data)
      webhook_data['action']
    end

    def self.pr_merged?(webhook_data)
      webhook_data['pull_request']['merged'].present?
    end

    def self.pr_base_ref(webhook_data)
      webhook_data['pull_request']['base']['ref']
    end

    def self.pr_html_url(webhook_data)
      webhook_data['pull_request']['html_url']
    end
  end
end
