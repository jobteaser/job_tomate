require 'slack-ruby-bot'

Dir[File.expand_path('../slack_bot/**/*.rb', __FILE__)].each do |f|
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
