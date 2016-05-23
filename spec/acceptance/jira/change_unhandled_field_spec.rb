require "spec_helper"
require "errors/jira"

describe "change unhandled field" do
  include WebhooksHelpers
  include WebmockHelpers

  def play_request
    post_webhook_jira(payload_name, payload_override)
  end
  let(:payload_name) { :issue_updated_changed_field_category }
  let(:payload_override) { {} }

  it "is successful and does nothing" do
    play_request
    expect(last_response).to be_ok
  end
end
