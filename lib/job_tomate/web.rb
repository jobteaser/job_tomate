require "sinatra/base"
require "sinatra/namespace"

module JobTomate

  # Web app module providing web endpoints:
  #   - root (/) with status JSON response,
  #   - webhooks.
  #
  # Webhooks are defined in /triggers/webhooks.
  class Web < Sinatra::Base
    register Sinatra::Namespace
    set :show_exceptions, false if ENV["APP_ENV"] == "test"

    get "/" do
      { status: "ok" }.to_json
    end

    # Extends the JobTomate::Web Sinatra app to handle webhook endpoints. These are defined in /triggers/webhooks.
    namespace "/webhooks" do
      base_path = File.expand_path("..", __FILE__)
      Dir[File.expand_path("../triggers/webhooks/**/*.rb", __FILE__)].each do |file|
        require file
        module_path = file.gsub(base_path, "").gsub(/\.rb\Z/, "")
        module_segments = module_path.split("/").reject(&:blank?)
        module_constant = (["JobTomate"] + module_segments.map(&:camelize)).join("::").constantize

        webhook = module_constant.definition
        send(webhook[:verb], webhook[:path]) do
          instance = module_constant.new
          instance.request = request
          JobTomate::Data::WebhookPayload.create(
            source: webhook[:name],
            data: instance.webhook_data
          )
          instance.run_events
          { status: "ok" }.to_json
        end
      end
    end
  end
end
