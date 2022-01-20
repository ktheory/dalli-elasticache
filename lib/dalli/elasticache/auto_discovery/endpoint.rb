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
        attr_reader :host
        attr_reader :port

        # Matches Strings like "my-host.cache.aws.com:11211"
        ENDPOINT_REGEX = /([-.a-zA-Z0-9]+):(\d+)/.freeze

        STATS_COMMAND  = "stats\r\n"
        CONFIG_COMMAND = "config get cluster\r\n"

        # Legacy command for version < 1.4.14
        OLD_CONFIG_COMMAND = "get AmazonElastiCache:cluster\r\n"

        def initialize(endpoint)
          ENDPOINT_REGEX.match(endpoint) do |m|
            @host = m[1]
            @port = m[2].to_i
          end
        end

        # A cached ElastiCache::StatsResponse
        def stats
          @stats ||= stats_from_remote
        end

        # A cached ElastiCache::ConfigResponse
        def config
          @config ||= config_from_remote
        end

        # The memcached engine version
        def engine_version
          stats.version
        end

        protected

        def stats_from_remote
          data = remote_command(STATS_COMMAND)
          StatsResponse.new(data)
        end

        def config_from_remote
          data = if engine_version < Gem::Version.new('1.4.14')
                   remote_command(OLD_CONFIG_COMMAND)
                 else
                   remote_command(CONFIG_COMMAND)
                 end
          ConfigResponse.new(data)
        end

        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def remote_command(command)
          socket = TCPSocket.new(@host, @port)
          socket.puts command

          data = +''
          until (line = socket.readline).include?('END')
            data << line
          end

          socket.close
          data
        end
      end
    end
  end
end
