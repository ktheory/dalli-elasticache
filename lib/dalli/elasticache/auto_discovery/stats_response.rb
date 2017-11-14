module Dalli
  module Elasticache
    module AutoDiscovery
      
      # This class wraps the raw ASCII response from an Auto Discovery endpoint
      # and provides methods for extracting data from that response.
      #
      # http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.AddingToYourClientLibrary.html
      
      class StatsResponse
        
        # The raw response text
        attr_reader :text
        
        # Matches the version line of the response
        VERSION_REGEX = /^STAT version ([0-9.]+).*$/
        
        def initialize(response_text)
          @text = response_text.to_s
        end
        
        # Extract the engine version stat
        #
        # Returns a Gem::Version
        def version
          Gem::Version.new(VERSION_REGEX.match(@text)[1])
        end
      end
    end
  end
end
