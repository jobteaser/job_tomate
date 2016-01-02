require 'sinatra/base'

module JobTomate

  # Extending JobTomate::Web with the root route.
  class Web < Sinatra::Base
    get '/' do
      { status: 'ok' }.to_json
    end
  end
end
