require 'spec_helper'
require 'job_tomate/commands/slack/send_message'

describe JobTomate::Commands::Slack::SendMessage do

  describe '.run(text, [channel, username, icon_url, icon_emoji])' do

    let(:webhook_url) { 'https://test.slack.com' }
    before { ENV['SLACK_WEBHOOK_URL'] = webhook_url }

    # TODO: test using webmock instead of stubbing
    #   HTTParty
    it 'sends the correct payload using HTTParty' do
      expect(HTTParty).to receive(:send).with(
        :post,
        webhook_url,
        {
          headers: { 'Content-Type' => 'application/json' },
          body: {
            text: 'test',
            channel: '@channel',
            username: described_class.const_get(:DEFAULT_USERNAME),
            icon_emoji: described_class.const_get(:DEFAULT_ICON_EMOJI)
          }.to_json
        }
      )
      described_class.run('test',
        channel: '@channel'
      )
    end
  end
end
