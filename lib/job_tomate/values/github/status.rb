require "data/user"

module JobTomate
  module Values
    module Github

      # A value object to encapsulate a Github pull request.
      class Status
        STORED_DATA_ATTRIBUTES = %w(
          branches
          context
          description
          name
          sender
          state
          target_url
        ).freeze

        attr_reader :data

        # @param data [Hash] the Github webhook payload. Only the relevan
        #   part gets stored (`STORED_DATA_ATTRIBUTES`)
        #   the Github webhook payload.
        def initialize(data)
          @data = data.slice(*STORED_DATA_ATTRIBUTES)
        end

        def sender_github_user
          data["sender"]["login"]
        end

        def sender_user
          JobTomate::Data::User.where(github_user: sender_github_user).first
        end

        def branch
          data["branches"].first["name"]
        end

        def context
          data["context"]
        end

        def description
          data["description"]
        end
      end
    end
  end
end
