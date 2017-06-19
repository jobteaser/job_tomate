# frozen_string_literal: true

require "sinatra/base"
require "sinatra/namespace"
require "triggers/webhooks"

module JobTomate

  # Web app module providing web endpoints:
  #   - root (/) with status JSON response,
  #   - webhooks.
  #
  # Webhooks are defined in /triggers/webhooks.
  class Web < Sinatra::Base
    register Sinatra::Namespace
    set :show_exceptions, false if ENV["RACK_ENV"] == "test"

    get "/" do
      { status: "ok" }.to_json
    end

    # Extends the JobTomate::Web Sinatra app to handle webhook endpoints.
    # These are defined in /triggers/webhooks.
    #
    # A `/webhooks/some_integration` webhook will use the
    # `JobTomate::Triggers::Webhooks::SomeIntegration` class for processing.
    #
    # You may easily "replay" a webhook (since they are stored in the DB).
    # For example, assuming the last stored webhook is a JIRA webhook:
    #
    #     JobTomate::Triggers::Webhooks::Jira.new.run_events(
    #       JobTomate::Data::StoredWebhook.last.value
    #     )
    #
    namespace "/webhooks" do
      async_web_transactions_enabled = ENV["ASYNC_WEB_TRANSACTIONS_ENABLED"] == "true"
      base_path = File.expand_path("..", __FILE__)
      Dir[File.expand_path("../triggers/webhooks/**/*.rb", __FILE__)].each do |file|
        require file
        module_path = file.gsub(base_path, "").gsub(/\.rb\Z/, "")
        module_segments = module_path.split("/").reject(&:blank?)
        trigger_module = (["JobTomate"] + module_segments.map(&:camelize)).join("::").constantize
        webhook_def = trigger_module.definition

        send(webhook_def[:verb], webhook_def[:path]) do
          begin
            transaction_uuid = JobTomate::Triggers::Webhooks.run(
              trigger: trigger_module.new,
              request: request,
              async: async_web_transactions_enabled
            )
          rescue JobTomate::Triggers::Webhooks::InvalidWebhook
            return [400, { status: "invalid webhook" }.to_json]
          end
          { status: "ok", transaction_uuid: transaction_uuid }.to_json
        end
      end
    end
  end
end
