require 'active_support/all'

module JobTomate
  module Input
    module Jira
      module Helpers

        def issue_key(webhook_data)
          webhook_data['issue']['key']
        end

        # Returns true if the webhook has been called for
        # a new issue.
        def issue_created?(webhook_data)
          webhook_data['webhookEvent'] == 'jira:issue_created'
        end

        # Returns true if the webhook has been called
        # because the issue was changed on the specified
        # field.
        def issue_changed?(field, webhook_data)
          change(field, webhook_data).present?
        end

        # Returns the changelog item for the specified field
        # (first encountered)
        def change(field, webhook_data)
          key = issue_key(webhook_data)

          changelog = webhook_data['changelog']
          if changelog.blank? || (items = changelog['items']).empty?
            LOGGER.debug "No changelog or changelog items for issue #{key}"
            return nil
          end

          items.find { |item| item['field'] == field }
        end
      end
    end
  end
end
