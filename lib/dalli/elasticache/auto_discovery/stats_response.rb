# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      # This class wraps the raw ASCII response from a stats call to an
      # Auto Discovery endpoint and provides methods for extracting data
      # from that response.
      #
      # http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.AddingToYourClientLibrary.html
      class StatsResponse
        # The raw response text
        attr_reader :text

        # Matches the version line of the response
        VERSION_REGEX = /^STAT version ([0-9.]+|unknown)\s*/.freeze

        def initialize(response_text)
          @text = response_text.to_s
        end

        # Extract the engine version stat
        #
        # Returns a string
        def engine_version
          m = VERSION_REGEX.match(@text)
          return '' unless m && m[1]

          m[1]
        end
      end
    end
  end
end
