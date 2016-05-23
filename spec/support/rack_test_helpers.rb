require "web"

# Helpers for rack/test tests:
#   - once included, already includes Rack::Test::Methods
#     and defines the appropriate `app` method so you don't
#     have to do it in every Rack::Test spec file
#   - defines some sugar-syntax helpers for performing
#     JSON requests:
#     - post_json
#
# Include it by adding `include RackHelpers` in your top-level
# `describe` block.
module RackTestHelpers
  include Rack::Test::Methods

  def app
    JobTomate::Web
  end

  def post_json(path, payload)
    post path, payload, "CONTENT_TYPE" => "application/json"
  end
end
