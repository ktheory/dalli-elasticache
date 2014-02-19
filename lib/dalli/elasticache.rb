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
      s = TCPSocket.new(config_host, config_port)

      stats = get_response(s, "stats\r\n")

      # Pull out the version STAT from the server response
      version_stat = stats.select { |s| s =~ /version/ }

      # Produes a string like: ["STAT version 1.4.5\r\n"]; pull the version out
      memcached_version = Gem::Version.new(version_stat.split(' ')[2])

      # As of 1.4.14 or higher, AWS introduced the "config" command to get cluster
      # information. For older versions of the server, hosts are stored under the key
      # "AmazonElastiCache:cluster". For more details see:
      #
      # http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.AddingToYourClientLibrary.html
      if memcached_version >= Gem::Version.new("1.4.14")
        data = get_response(s, "config get cluster\r\n")
      else
        data = get_response(s, "get AmazonElastiCache:cluster\r\n")
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

    private
    def get_response(socket, command)
      socket.puts(command)
      data = []
      while (line = socket.gets) != "END\r\n"
        data << line
      end
      data
    end

  end
end
