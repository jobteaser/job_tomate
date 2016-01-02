require 'sinatra/base'

module JobTomate

  # Web app module providing web endpoints:
  #   - root (/) with status JSON response,
  #   - webhooks.
  #
  # Usage
  #   - Extend by adding files in lib/job_tomate/web
  #   - For webhooks, see lib/job_tomate/web/webhooks
  class Web < Sinatra::Base
    require 'job_tomate/endpoints/root'
    require 'job_tomate/endpoints/webhooks'
  end
end
