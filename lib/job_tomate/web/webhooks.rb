require "sinatra/base"
require "sinatra/namespace"

module JobTomate

  # Extends the JobTomate::Web Sinatra app to handle webhook endpoints.
  # New webhooks may be added easily by adding files in the web/webhooks
  # directory (see example below).
  #
  # How to add new webhooks
  # -----------------------
  # TODO: write explanation
  #
  class Web < Sinatra::Base
    register Sinatra::Namespace

    namespace "/webhooks" do
      base_path = File.expand_path("..", __FILE__)
      Dir[File.expand_path("../webhooks/**/*.rb", __FILE__)].each do |file|
        require file
        module_path = file.gsub(base_path, "").gsub(/\.rb\Z/, "")
        module_segments = module_path.split("/").reject(&:blank?)
        module_constant = (["JobTomate"] + module_segments.map(&:camelize)).join("::").constantize

        instance = module_constant.new
        webhook = instance.definition
        send(webhook[:verb], webhook[:path]) do
          webhook_data = instance.extract_webhook_data(request)
          JobTomate::Data::WebhookPayload.create(
            source: webhook[:name],
            data: webhook_data
          )
          instance.run_events(webhook_data)
          { status: "ok" }.to_json
        end
      end
    end
  end
end
