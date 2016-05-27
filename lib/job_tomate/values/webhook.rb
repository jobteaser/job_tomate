module JobTomate
  module Values

    # A value class to hold webhook request data.
    #
    # Extracts headers from `request.env` (by ignoring keys prefixed by downcase
    # strings).
    class Webhook
      attr_reader :body
      attr_reader :headers

      def self.with_request(request)
        new extract_headers(request), extract_body(request)
      end

      def initialize(headers, body)
        @headers = headers
        @body = body
      end

      def parsed_body
        body.empty? ? { error: "no body" } : JSON.parse(body)
      end

      def self.extract_headers(request)
        request.env.reject do |k, _v|
          k =~ /\A[a-w]/
        end
      end

      def self.extract_body(request)
        request.body.rewind
        request.body.read
      end
    end
  end
end
