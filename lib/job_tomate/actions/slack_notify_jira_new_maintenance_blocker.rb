require "commands/slack/send_message"
require "support/service_pattern"

module JobTomate
  module Actions

    # Determines if the creates issue (passed as argument)
    # is a maintenance blocker and notifies the Slack
    # #maintenance channel if it's the case.
    class SlackNotifyJIRANewMaintenanceBlocker
      extend ServicePattern
      NOTIFIED_CHANNEL = "#maintenance"

      # @param issue [Values::JIRA::Issue]
      def run(issue)
        return unless issue.maintenance?
        return unless issue.blocker?
        link = "<#{issue.link}|#{issue.key}>"
        message = "New blocker issue has just been created! => #{link}"
        Commands::Slack::SendMessage.run(
          message,
          channel: NOTIFIED_CHANNEL
        )
      end
    end
  end
end
