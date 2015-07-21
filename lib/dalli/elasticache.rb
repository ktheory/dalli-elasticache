require 'dalli'
require 'socket'
require 'dalli/elasticache/version'
require 'dalli/elasticache/auto_discovery/endpoint'
require 'dalli/elasticache/auto_discovery/config_response'
require 'dalli/elasticache/auto_discovery/stats_response'

module Dalli
  class ElastiCache
    attr_reader :endpoint, :options
    
    def initialize(config_endpoint, options={})
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint)
      @options = options
    end
    
    # Dalli::Client configured to connect to the cluster's nodes
    def client
      Dalli::Client.new(servers, options)
    end
    
    # The number of times the cluster configuration has been changed
    #
    # Returns an integer
    def version
      endpoint.config.version
    end
    
    # The cache engine version of the cluster
    def engine_version
      endpoint.engine_version
    end
    
    # List of cluster server nodes with ip addresses and ports
    # Always use host name instead of private elasticache IPs as internal IPs can change after a node is rebooted
    def servers
      endpoint.config.nodes.map{ |h| "#{h[:host]}:#{h[:port]}" }
    end
    
    # Clear all cached data from the cluster endpoint
    def refresh
      config_endpoint = "#{endpoint.host}:#{endpoint.port}"
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint)
      
      self
    end
  end
end
