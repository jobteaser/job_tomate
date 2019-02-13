module JobTomate
  module Values
    module Github

      # A value object to encapsulate a Github pull request.
      class PullRequest
        attr_reader :data

        # @param data [Hash] the "pull_request" values from
        #   the Github webhook payload.
        def initialize(data)
          @data = data
        end

        def base_ref
          data["base"]["ref"]
        end

        def head_ref
          data["head"]["ref"]
        end

        def html_url
          data["html_url"]
        end

        def merged?
          data["merged"] == true
        end

        def jira_issue_key
          @jira_issue_key ||= head_ref[/(jt|cs|js)-[\d]+/i]
        end
      end
    end
  end
end
