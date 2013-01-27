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

    def config_get_cluster
      # TODO: handle timeouts
      s = TCPSocket.new(config_host, config_port)
      s.puts "config get cluster\r\n"
      data = []
      while (line = s.gets) != "END\r\n"
        data << line
      end

      s.close
      data
    end

    def data
      return @data if @data
      raw_data = config_get_cluster
      version = raw_data[1].to_i
      instance_data = raw_data[2].split(/\s+/)
      instances = instance_data.map{ |raw| host, ip, port = raw.split('|'); {:host => host, :ip => ip, :port => port} }
      @data = { :version => version, :instances => instances }
    end

    def version
      data[:version]
    end

    def servers
      data[:instances].map{ |i| "#{i[:ip]}:#{i[:port]}" }
    end

  end
end
