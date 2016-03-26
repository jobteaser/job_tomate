require "sinatra/base"

module JobTomate

  # Extending JobTomate::Web with the root route.
  class Web < Sinatra::Base
    set :show_exceptions, false if ENV["APP_ENV"] == "test"

    get "/" do
      { status: "ok" }.to_json
    end
  end
end
