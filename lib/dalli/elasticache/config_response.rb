module Dalli
  
  # This class wraps the raw ASCII response from an Auto Discovery endpoint and
  # provides methods for extracting data from that response.
  #
  # http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.AddingToYourClientLibrary.html
  
  class ElastiCacheConfigResponse
    
    attr_reader :text
    
    # Matches the version line of the response
    VERSION_REGEX = /^(\d+)\r\n$/
    
    # Matches strings like "my-cluster.001.cache.aws.com|10.154.182.29|11211"
    NODE_REGEX = /(([-.a-zA-Z0-9]+)\|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\|(\d+))/
    NODE_LIST_REGEX = /^(#{NODE_REGEX}\s*)+\r\n$/
    
    def initialize(response_text)
      @text = response_text.to_s
    end
    
    # The number of times the configuration has been changed
    #
    # Returns an integer
    def version
      VERSION_REGEX.match(@text)[1].to_i
    end
    
    # Node hosts, ip addresses, and ports
    #
    # Returns an Array of Hashes with values for :host, :ip and :port
    def nodes
      NODE_LIST_REGEX.match(@text).to_s.scan(NODE_REGEX).map do |match|
        {
          :host => match[1],
          :ip   => match[2],
          :port => match[3].to_i
        }
      end
    end
    
  end
end
