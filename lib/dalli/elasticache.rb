require 'dalli'
require 'socket'
require 'dalli/elasticache/version'

module Dalli
  class ElastiCache
    attr_accessor :config_host, :config_port, :options

    def initialize(config_endpoint, options={})
      @config_host, @config_port = config_endpoint.split(':')
      @config_port ||= 11211
      @options = options
      @old = options.delete(:old) || false

    end

    def client
      Dalli::Client.new(servers, options)
    end

    def refresh
      # Reset data
      @data = nil
      data

      self
    end

    def data
      return @data if @data
      if @old == false
        raw_data = get_response_from_endpoint("config get cluster\r\n")
      end
      if @old || raw_data.blank? #fallback old command (1.4.5)
        raw_data = get_response_from_endpoint("get AmazonElastiCache:cluster\r\n")
      end
      
      version = 0
      instances = []
      begin
        if raw_data.size > 2
          version = raw_data[1].to_i
          instance_data = raw_data[2].split(/\s+/)
          instances = instance_data.map{ |raw| host, ip, port = raw.split('|'); {:host => host, :ip => ip, :port => port} }
        end
      rescue e
        #ignore
      ensure
        if version == 0 || instances.blank?
          # fallback to source endpoint
          require 'resolv'
          ip = Resolv.getaddress(config_host)
          version = "unknown"
          instances = [{:host => config_host, :ip => ip, :port => config_port}]
        end
      end
      @data = { :version => version, :instances => instances }
    end

    def version
      data[:version]
    end

    def servers
      data[:instances].map{ |i| "#{i[:ip]}:#{i[:port]}" }
    end

    private

    def get_response_from_endpoint(command)
      socket = TCPSocket.new(config_host, config_port)
      socket.puts command
      
      data = []
      while !["END\r\n","ERROR\r\n", nil].include?(line = get_from_socket_or_timeout(socket)) 
        data << line
      end
      socket.close
      data
    end

    def get_from_socket_or_timeout(socket, timeout=0.5)
      sockets_ready = IO.select([socket], nil, nil, timeout)
      if sockets_ready.nil?
        nil
      else
        sockets_ready[0][0].gets
      end
    end

  end
end
