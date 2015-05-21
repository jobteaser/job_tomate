require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require_relative '../worried_app'

describe Worried do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /status' do
    it 'should respond a successful response' do
      get '/status'
      last_response.should be_ok
    end
  end

  describe 'server alert policy opened' do
    let(:json) { File.read File.expand_path('../fixtures/server_alert_policy_opened.json', __FILE__) }
    before { ENV['PUSHBULLET_API_KEY'] = 'key' }

    it 'should send a push event to PushBullet with the appropriate title and message' do
      req = stub_request(:post, 'https://key:@api.pushbullet.com/v2/pushes').with do |request|
        request.body.should == 'type=note&title=New+alert+on+my.server.local&body=Alert+opened%3A+Disk+IO+%3E+85%25%5Cn%5Cn2014-03-04T14%3A41%3A07-08%3A00'
      end
      post '/new_relic/push_bullet', {alert: json}, 'CONTENT_TYPE' => 'application/json'
      req.should have_been_requested
    end
  end
end