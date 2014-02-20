require 'dalli'
require 'socket'
require 'dalli/elasticache/version'
require 'dalli/elasticache/wrapper'

module Dalli
  class Wrapper
    def initialize(opts)
      @config_host = opts[:config_host]
      @config_port = opts[:config_port]
      @options = opts[:options]
      @refresh_interval = opts[:refresh_interval]
      @dalli_client = Dalli::Client.new(servers, options)
      @last_updated_at = 0
    end

    def method_missing(method, *args, &block)
      if !@data || ((Time.now - @last_updated_at) > @refresh_interval)
        refresh
        @last_updated_at = Time.now
        @dalli_client = Dalli::Client.new(servers, options)
      end
      @dalli_client.send(method, args)
    end

    private
    
    def options
      @options
    end

    def config_get_cluster
      s = TCPSocket.new(config_host, config_port)
      s.puts "config get cluster\r\n"
      data = []
      while (line = s.gets) != "END\r\n"
        data << line
      end
      s.close
      data
    end
    
    def config_host
      @config_host
    end
    
    def config_port
      @config_port
    end

    def data
      return @data if @data
      raw_data = config_get_cluster
      version = raw_data[1].to_i
      instance_data = raw_data[2].split(/\s+/)
      instances = instance_data.map{ |raw| host, ip, port = raw.split('|'); {:host => host, :ip => ip, :port => port} }
      @data = { :version => version, :instances => instances }
    end

    def servers
      data[:instances].map{ |i| "#{i[:ip]}:#{i[:port]}" }
    end

    def refresh
      # Reset data
      @data = nil
      data
      self
    end
  end

  class ElastiCache
    attr_accessor :config_host, :config_port, :options

    def initialize(config_endpoint, options={})
      @config_host, @config_port = config_endpoint.split(':')
      @config_port ||= 11211
      @options = options
      @refresh_interval = options[:refresh_interval] || 300
      @opts = { :config_host => @config_host, :config_port => @config_port, :options => options, :refresh_interval => @refresh_interval }
    end

    def client
      Dalli::Wrapper.new(@opts)
    end

    def version
      data[:version]
    end
  end
end
