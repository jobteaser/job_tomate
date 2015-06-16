require 'active_support/all'

module JobTomate
  class JiraProcessor
    # Perform a run where:
    #   - it takes parsed webhooks datas send by github in params,
    #   - defines params from the webhook in order to make a POST request on Jira,
    #   - set the correct assignee considering the ticket status.
    def self.run(webhook_data)
      new_status = webhook_data['changelog']['items'].first['toString']
      user_name = webhook_data['user']['key']
      issue_key = webhook_data['issue']['key']
      developer = webhook_data['issue']['fields']['customfield_10600'].try(:[], 'key')
      reviewer = webhook_data['issue']['fields']['customfield_10601'].try(:[], 'key')
      functional_reviewer = 'harold.sirven'

      user = JobTomate::User.where(jira_username: user_name).first

      if developer.nil? && (new_status == 'Ready for Release' || new_status == 'In Development')
        developer = webhook_data['user']['name']
      end
      if (reviewer.nil? && new_status == 'In Review') && webhook_data['user']['name'] != developer
        reviewer = webhook_data['user']['name']
      end

      assignee = case new_status
      when 'In Functional Review'
        functional_reviewer
      when 'In Review'
        reviewer
      when 'Ready for Release', 'In Development'
        developer
      end
      # if webhook_data['issue']['fields']['subtasks'].first['fields']['issuetype']['subtask']

      # end
      JobTomate::JiraClient.assign_user(issue_key, user.jira_username, user.jira_password, assignee, developer, reviewer)
    end
  end
end