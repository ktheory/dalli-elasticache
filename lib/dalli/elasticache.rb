# frozen_string_literal: true

require 'dalli'
require 'socket'
require 'timeout'
require_relative 'elasticache/version'
require_relative 'elasticache/auto_discovery/endpoint'
require_relative 'elasticache/auto_discovery/base_command'
require_relative 'elasticache/auto_discovery/node'
require_relative 'elasticache/auto_discovery/config_response'
require_relative 'elasticache/auto_discovery/config_command'
require_relative 'elasticache/auto_discovery/stats_response'
require_relative 'elasticache/auto_discovery/stats_command'

module Dalli
  ##
  # Dalli::Elasticache provides an interface for providing a configuration
  # endpoint for a memcached cluster on ElasticCache and retrieving the
  # list of addresses (hostname and port) for the individual nodes of that cluster.
  #
  # This allows the caller to pass that server list to Dalli, which then
  # distributes cached items consistently over the nodes.
  ##
  class ElastiCache
    DEFAULT_TIMEOUT = 5

    attr_reader :endpoint, :options

    ##
    # Creates a new Dalli::ElasticCache instance.
    #
    # config_endpoint - a String containing the host and (optionally) port of the
    # configuration endpoint for the cluster.  If not specified the port will
    # default to 11211.  The host must be either a DNS name, an IPv4 address, or
    # a bracketed IPv6 address.
    # dalli_options - a set of options passed to the Dalli::Client that is returned
    # by the client method.  Otherwise unused.
    # timeout: - connect and read timeout in seconds for auto-discovery TCP calls.
    # Defaults to 5 seconds.
    ##
    def initialize(config_endpoint, dalli_options = {}, timeout: DEFAULT_TIMEOUT, ssl_context: nil)
      @timeout = timeout
      @ssl_context = ssl_context
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, timeout:, ssl_context:)
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
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, timeout: @timeout,
                                                                                   ssl_context: @ssl_context)
      self
    end
  end
end
