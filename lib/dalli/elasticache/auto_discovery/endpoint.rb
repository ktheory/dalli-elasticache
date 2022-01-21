# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # This is a representation of the configuration endpoint for
      # a memcached cluster.  It encapsulates information returned from
      # that endpoint.
      ##
      class Endpoint
        # Endpoint configuration
        attr_reader :host, :port

        # Matches Strings like "my-host.cache.aws.com:11211"
        ENDPOINT_REGEX = /^([-.a-zA-Z0-9]+)(?::(\d+))?$/.freeze

        def initialize(addr)
          @host, @port = parse_endpoint_address(addr)
        end

        DEFAULT_PORT = 11_211
        def parse_endpoint_address(addr)
          m = ENDPOINT_REGEX.match(addr)
          raise ArgumentError, "Unable to parse configuration endpoint address - #{addr}" unless m

          [m[1], (m[2] || DEFAULT_PORT).to_i]
        end

        # A cached ElastiCache::StatsResponse
        def stats
          @stats ||= StatsCommand.new(@host, @port).response
        end

        # A cached ElastiCache::ConfigResponse
        def config
          @config ||= ConfigCommand.new(@host, @port, engine_version).response
        end

        # The memcached engine version
        def engine_version
          stats.engine_version
        end
      end
    end
  end
end
