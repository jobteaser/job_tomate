require_relative './config/boot.rb'
require 'job_tomate/bot'
require 'job_tomate/web'

Thread.new do
  begin
    JobTomate::Bot::App.instance.run
  rescue Exception => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

run JobTomate::Web
