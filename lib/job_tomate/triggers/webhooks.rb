# frozen_string_literal: true
module JobTomate
  module Triggers
    module Webhooks
      InvalidWebhook = Class.new(StandardError)

      # @param trigger: [Object] instance of a `JobTomate::Triggers`
      #   module
      # @param request:
      # @param async: [Boolean
      # @return [String] transaction UUID
      def self.run(trigger:, request:, async:)
        Transaction.new.run(trigger, request, async)
      end

      class Transaction

        def run(trigger, request, async)
          run_in_transaction(async: async) do |uuid|
            webhook_value = Values::Webhook.with_request(request)
            Data::StoredWebhook.create(
              transaction_uuid: uuid,
              headers: webhook_value.headers,
              body: webhook_value.body
            )
            trigger.run_events(webhook_value)
          end
        end

        private

        # @return [String] transaction UUID
        def run_in_transaction(async:, &block)
          raise("Missing block") unless block_given?
          if async
            uuid, _thread = run_transaction_async(&block)
            return uuid
          end
          run_transaction_sync(&block)
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
          yield(uuid)
          uuid
        end

        def generate_uuid
          SecureRandom.uuid
        end
      end
    end
  end
end
