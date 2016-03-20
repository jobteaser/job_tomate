require_relative "./config/boot.rb"
require "job_tomate/slackbot"
require "job_tomate/web"

# Starting Slack bot in a new thread
Thread.new do
  begin
    JobTomate::SlackBot::App.instance.run
  rescue StandardError => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

# Starting the Web Rack app
run JobTomate::Web
