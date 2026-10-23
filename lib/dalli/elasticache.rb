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
    DEFAULT_TIMEOUT = Dalli::Elasticache::AutoDiscovery::BaseCommand::DEFAULT_TIMEOUT

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
    # timeout: - timeout in seconds applied separately to each step of an auto-discovery
    # call: DNS resolution, TCP connect, TLS handshake, and reading the response.
    # Defaults to 5 seconds. Pass nil to disable.
    # ssl_context: - an OpenSSL::SSL::SSLContext to use TLS for the auto-discovery calls.
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
    #
    # Raises Dalli::Elasticache::AutoDiscovery::ResponseError if the response contains
    # no nodes, rather than handing Dalli an empty server list that only fails on first use
    def servers
      nodes = endpoint.config.nodes
      if nodes.empty?
        raise Dalli::Elasticache::AutoDiscovery::ResponseError,
              "No cache nodes found in auto discovery response from #{endpoint.host}:#{endpoint.port}"
      end

      nodes.map(&:to_s)
    end

    # Discards the cached discovery results so the next call re-queries the
    # configuration endpoint. Returns self.
    #
    # This does not change Dalli::Client instances already returned by #client;
    # call #client again to get one that uses the current node list.
    def refresh
      config_endpoint = "#{endpoint.host}:#{endpoint.port}"
      @endpoint = Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, timeout: @timeout,
                                                                                   ssl_context: @ssl_context)
      self
    end
  end
end
