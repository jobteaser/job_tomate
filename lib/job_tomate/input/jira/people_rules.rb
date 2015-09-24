require 'active_support/all'

module JobTomate
  module Input
    module Jira

      # Updates the peoples associated to the issue
      # (assignee, developer and reviewer).
      class PeopleRules

        # Applies the rules
        def self.apply(webhook_data)
          new_status = webhook_data['changelog']['items'].first['toString']
          user_name = webhook_data['user']['key']
          issue_key = webhook_data['issue']['key']
          developer = webhook_data['issue']['fields']['customfield_10600'].try(:[], 'key')
          reviewer = webhook_data['issue']['fields']['customfield_10601'].try(:[], 'key')
          functional_reviewer = 'harold.sirven'

          user = JobTomate::User.where(jira_username: user_name).first
          if user.nil?
            LOGGER.warn "User with JIRA username \"#{user_name}\" is unknown and cannot trigger JIRA API calls"
            user = JobTomate::User.first
          end

          if developer.nil? && (new_status == 'Ready for Release' || new_status == 'In Development')
            developer = webhook_data['user']['name']
          end
          if (reviewer.nil? && new_status == 'In Review') && webhook_data['user']['name'] != developer
            reviewer = webhook_data['user']['name']
          end

          assignee = (
            case new_status
            when 'In Development' then developer
            when 'In Functional Review' then functional_reviewer
            when 'In Review' then reviewer
            when 'Ready for Release' then developer
            end
          )

          JobTomate::Output::JiraClient.set_people(issue_key, user.jira_username, user.jira_password, assignee, developer, reviewer)
        end
      end
    end
  end
end
