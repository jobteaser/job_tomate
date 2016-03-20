require "sinatra/base"
require "sinatra/namespace"

module JobTomate
  module Webhooks

    # Superclass for webhooks handlers
    class Base
      attr_accessor :request

      def webhook_data
        @webhook_data = (
          request.body.rewind
          json = request.body.read
          json.empty? ? { error: "no body" } : JSON.parse(json)
        )
      end
    end
  end

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
