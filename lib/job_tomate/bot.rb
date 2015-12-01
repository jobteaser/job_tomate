require 'slack-ruby-bot'

Dir[File.expand_path('../bot/**/*.rb', __FILE__)].each do |f|
  require f
end

# The TomatoBot is a Slack bot that can handle advanced
# interactions through Slack.
module JobTomate
  module Bot
    class App < SlackRubyBot::App
    end
  end
end
