module Dalli
  class ElastiCacheEndpointResponse
    
    attr_reader :text
    
    # Matches the first line of the response
    CONFIG_REGEX = /CONFIG cluster (\d+) (\d+)/
    
    # Matches strings like "my-cluster.cache.aws.com|10.154.182.29|11211"
    NODE_REGEX = /(([-.a-zA-Z0-9]+)\|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\|(\d+))/
    
    def initialize(response_text)
      @text = response_text.to_s
    end
    
    def version
      CONFIG_REGEX.match(@text)[1]
    end
    
    # Returns an Array of Hashes with values for :host, :ip and :port
    def nodes
      @text.scan(NODE_REGEX).map do |match|
        {
          :host => match[1],
          :ip   => match[2],
          :port => match[3].to_i
        }
      end
    end
    
  end
end
