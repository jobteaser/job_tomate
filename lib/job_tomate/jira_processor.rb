require 'active_support/all'

module JobTomate
  class JiraProcessor

    # Perform a run where:
    #   - it takes parsed webhooks datas send by github in params,
    #   - defines params from the webhook in order to make a POST request on Jira,
    #   - set the correct comment considering the PR status.
    def self.run(webhook_data)
      new_status = webhook_data['changelog']['items'].first['toString']
      reviewer = webhook_data['issue']['fields']['customfield_10601']['key']
      developer = webhook_data['issue']['fields']['customfield_10600']['key']
      issue_key = webhook_data['issue']['key']
      user = JobTomate::User.where(jira_username: webhook_data['user']['key']).first
      assignee = case new_status
      when 'In Functional Review'
        'harold.sirven'
      when 'In Review'
        reviewer
      when ('Ready for Release' || 'In Development')
        developer
      end
      JobTomate::JiraClient.assign_user(issue_key, user.jira_username, user.jira_password, assignee)
    end
  end
end