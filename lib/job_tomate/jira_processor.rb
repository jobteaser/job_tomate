require 'active_support/all'

module JobTomate
  class JiraProcessor

    # Perform a run where:
    #   - it takes parsed webhooks datas send by github in params,
    #   - defines params from the webhook in order to make a POST request on Jira,
    #   - set the correct comment considering the PR status.
    def self.run(webhook_data)
      new_status = webhook_data['changelog']['items'].first['toString']
      user_to_assign = webhook_data['issue']['fields']['customfield_10601']['key']
      logger.info "ticket changed to #{new_status}, user to assigned is #{user_to_assign}"
    end
  end
end