require "slack-ruby-bot"

SlackRubyBot::Client.logger.level = Logger::INFO

Dir[File.expand_path("../triggers/slackbot_commands/*.rb", __FILE__)].each do |f|
  require f
end

# The TomatoBot is a Slack bot that can handle advanced
# interactions through Slack.
module JobTomate
  module SlackBot
    class App < SlackRubyBot::App
    end
  end
end
