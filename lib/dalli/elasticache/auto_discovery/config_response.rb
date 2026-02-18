# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      # This class wraps the raw ASCII response from an Auto Discovery endpoint
      # and provides methods for extracting data from that response.
      #
      # http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.AddingToYourClientLibrary.html
      class ConfigResponse
        # The raw response text
        attr_reader :text

        # Matches the version line of the response
        VERSION_REGEX = /^(\d+)\r?\n/

        # Matches strings like "my-cluster.001.cache.aws.com|10.154.182.29|11211"
        NODE_REGEX = /(([-.a-zA-Z0-9]+)\|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\|(\d+))/
        NODE_LIST_REGEX = /^(#{NODE_REGEX}\s*)+$/

        def initialize(response_text)
          @text = response_text.to_s
        end

        # The number of times the configuration has been changed
        #
        # Returns an integer
        def version
          m = VERSION_REGEX.match(@text)
          return -1 unless m

          m[1].to_i
        end

        # Node hosts, ip addresses, and ports
        #
        # Returns an Array of Hashes with values for :host, :ip and :port
        def nodes
          NODE_LIST_REGEX.match(@text).to_s.scan(NODE_REGEX).map do |match|
            Node.new(match[1], match[2], match[3].to_i)
          end
        end
      end
    end
  end
end
