require 'sinatra/base'
require 'sinatra/namespace'
require 'job_tomate/input/github/processor'
require 'job_tomate/input/jira/processor'
require 'job_tomate/data/webhook_payload'

module JobTomate

  # Sinatra Rack app to handle web requests (app status, webhooks...)
  #
  # How to add new webhooks
  # -----------------------
  # Example code:
  #
  # ```ruby (lib/job_tomate/webhooks/awesome_hook.rb)
  # module JobTomate
  #   module Webhooks
  #     class AwesomeHook
  #
  #       # The returned lambda is ran in the context of the
  #       # Sinatra web app, in the '/webhooks' route namespace.
  #       # So you're free to use Sinatra API methods.
  #       def self.define_webhooks
  #         lambda do
  #           post '/awesome_action' do
  #             ...
  #           end
  #         end
  #       end
  #    end
  # end
  # ```
  class Web < Sinatra::Base
    register Sinatra::Namespace

    get '/' do
      { status: 'ok' }.to_json
    end

    namespace '/webhooks' do
      base_path = File.expand_path('..', __FILE__)
      Dir[File.expand_path('../webhooks/**/*.rb', __FILE__)].each do |file|
        require file
        module_path = file.gsub(base_path, '').gsub(/\.rb\Z/, '')
        module_segments = module_path.split('/').reject(&:blank?)
        module_constant = (['JobTomate'] + module_segments.map(&:camelize)).join('::').constantize
        instance_exec(&(module_constant.define_webhooks))
      end
    end
  end
end
