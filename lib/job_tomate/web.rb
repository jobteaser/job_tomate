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
    set :show_exceptions, false if ENV["RACK_ENV"] == "test"
    enable :async_web_transactions

    InvalidWebhook = Class.new(StandardError)

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
      base_path = File.expand_path("..", __FILE__)
      Dir[File.expand_path("../triggers/webhooks/**/*.rb", __FILE__)].each do |file|
        require file
        module_path = file.gsub(base_path, "").gsub(/\.rb\Z/, "")
        module_segments = module_path.split("/").reject(&:blank?)
        trigger_module = (["JobTomate"] + module_segments.map(&:camelize)).join("::").constantize

        webhook_def = trigger_module.definition
        send(webhook_def[:verb], webhook_def[:path]) do
          transaction_uuid = run_transaction do |uuid|
            webhook_value = JobTomate::Values::Webhook.with_request(request)
            JobTomate::Data::StoredWebhook.create(
              transaction_uuid: uuid,
              headers: webhook_value.headers,
              body: webhook_value.body
            )
            begin
              trigger_module.new.run_events(webhook_value)
            rescue InvalidWebhook
              return [400, { status: "invalid webhook" }.to_json]
            end
          end
          { status: "ok", transaction_uuid: transaction_uuid }.to_json
        end
      end
    end

    private

    def run_transaction(async: settings.async_web_transactions?, &block)
      raise("Missing block") unless block_given?
      async ? run_transaction_async(&block) : run_transaction_sync(&block)
    end

    def run_transaction_async
      uuid = generate_uuid
      Thread.new do
        Thread.current.thread_variable_set("transaction_uuid", uuid)
        yield(uuid)
      end
      uuid
    end

    def run_transaction_sync
      uuid = generate_uuid
      yield
      uuid
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
