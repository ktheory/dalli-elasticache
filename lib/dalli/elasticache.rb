require 'dalli'
require 'socket'
require 'dalli/elasticache/version'
require 'dalli/elasticache/config_response'

module Dalli
  class ElastiCache
    attr_accessor :config_host, :config_port, :options

    def initialize(config_endpoint, options={})
      @config_host, @config_port = config_endpoint.split(':')
      @config_port ||= 11211
      @options = options

    end

    def client
      Dalli::Client.new(servers, options)
    end

    def version
      response.version
    end

    def servers
      response.servers.map{ |h| "#{h[:ip]}:#{h[:port]}" }
    end
    
    def refresh
      # Reset data
      @response = nil
      response

      self
    end
    
    protected
    
    def response
      @response ||= Dalli::ElastiCacheEndpointResponse.new(raw_cluster_response)
    end
    
    def raw_cluster_response
      socket = TCPSocket.new(config_host, config_port)
      socket.puts "config get cluster\r\n"
      
      data = ""
      while (line = socket.gets)
        data << line
      end

      socket.close
      data
    end

  end
end
