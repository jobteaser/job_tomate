# frozen_string_literal: true

require "spec_helper"
require "errors/jira"

describe "other scenarios" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end

  let(:payload_override) { {} }

  context "issue created" do
    let(:payload_name) { :issue_created }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end

  context "issue updated on a field with no corresponding workflow" do
    let(:payload_name) { :issue_updated_changed_field_category }

    it "is successful and does nothing" do
      play_request
      expect(last_response).to be_ok
    end
  end
end
