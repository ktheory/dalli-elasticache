# frozen_string_literal: true

require 'dalli'
require 'socket'
require 'dalli/elasticache/version'
require 'dalli/elasticache/auto_discovery/endpoint'
require 'dalli/elasticache/auto_discovery/base_command'
require 'dalli/elasticache/auto_discovery/node'
require 'dalli/elasticache/auto_discovery/config_response'
require 'dalli/elasticache/auto_discovery/config_command'
require 'dalli/elasticache/auto_discovery/stats_response'
require 'dalli/elasticache/auto_discovery/stats_command'

module Dalli
  ##
  # Dalli::Elasticache provides an interface for providing a configuration
  # endpoint for a memcached cluster on ElasticCache and retrieving the
  # list of addresses (IP and port) for the individual nodes of that cluster.
  #
  # This allows the caller to pass that server list to Dalli, which then
  # distributes cached items consistently over the nodes.
  ##
  class ElastiCache
    attr_reader :endpoint, :options

    ##
    # Creates a new Dalli::ElasticCache instance.
    #
    # config_endpoint - a String containing the host and (optionally) port of the
    # configuration endpoint for the cluster.  If not specified the port will
    # default to 11211.  The host must be either a DNS name or an IPv4 address.  IPv6
    # addresses are not handled at this time.
    # dalli_options - a set of options passed to the Dalli::Client that is returned
    # by the client method.  Otherwise unused.
    ##
    def initialize(config_endpoint, dalli_options = {})
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint)
      @options = dalli_options
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
    #
    # Returns a string
    def engine_version
      endpoint.engine_version
    end

    # List of cluster server nodes with ip addresses and ports
    # Always use host name instead of private elasticache IPs as internal IPs can change after a node is rebooted
    def servers
      endpoint.config.nodes.map(&:to_s)
    end

    # Clear all cached data from the cluster endpoint
    def refresh
      config_endpoint = "#{endpoint.host}:#{endpoint.port}"
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint)

      self
    end
  end
end
