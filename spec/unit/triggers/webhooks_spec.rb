# frozen_string_literal: true

require "spec_helper"

class SpecTriggerModule
  def run_events(_webhook); end
end

describe JobTomate::Triggers::Webhooks do

  describe ".run(trigger:, webhook:, request:)" do
    let(:trigger) { SpecTriggerModule.new }
    let(:request_body) { double("request_body", rewind: nil, read: "") }
    let(:request) { double("request", env: {}, body: request_body) }

    subject do
      described_class.run(
        trigger: trigger,
        request: request,
        async: false
      )
    end

    it "executes `trigger_module#run_events(webhook)`" do
      expect(trigger).to receive(:run_events)
      subject
    end

    it "stores the webhook with the same transaction UUID as returned" do
      tx_uuid = subject
      stored_webhook = JobTomate::Data::StoredWebhook.last
      expect(stored_webhook.transaction_uuid).to eq(tx_uuid)
    end
  end
end
