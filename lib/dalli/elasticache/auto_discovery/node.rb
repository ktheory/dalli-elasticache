# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Represents a single memcached node in the
      # cluster.
      ##
      class Node
        attr_reader :host, :ip, :port

        def initialize(host, ip, port)
          @host = host
          @ip = ip
          @port = port
        end

        def ==(other)
          host == other.host &&
            ip == other.ip &&
            port == other.port
        end

        def eql?(other)
          self == other
        end

        def hash
          [host, ip, port].hash
        end

        def to_s
          "#{@host}:#{@port}"
        end
      end
    end
  end
end
