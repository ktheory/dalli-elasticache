module Dalli
  module Elasticache
    module AutoDiscovery
      class Endpoint
        class Timeout < StandardError; end;
        
        # Endpoint configuration
        attr_reader :host
        attr_reader :port
        attr_reader :timeout
    
        # Matches Strings like "my-host.cache.aws.com:11211"
        ENDPOINT_REGEX = /([-.a-zA-Z0-9]+):(\d+)/
    
        STATS_COMMAND  = "stats\r\n"
        CONFIG_COMMAND = "config get cluster\r\n"
        # Legacy command for version < 1.4.14
        OLD_CONFIG_COMMAND = "get AmazonElastiCache:cluster\r\n"
    
        def initialize(endpoint, timeout)
          ENDPOINT_REGEX.match(endpoint) do |m|
            @host = m[1]
            @port = m[2].to_i
          end
          @timeout = timeout
        end
    
        # A cached ElastiCache::StatsResponse
        def stats
          @stats ||= get_stats_from_remote
        end
    
        # A cached ElastiCache::ConfigResponse
        def config
          @config ||= get_config_from_remote
        end
    
        # The memcached engine version
        def engine_version
          stats.version
        end
    
        protected
    
        def with_socket(&block)
          TCPSocket.new(config_host, config_port)
        end
    
        def get_stats_from_remote
          data = remote_command(STATS_COMMAND)
          StatsResponse.new(data)
        end
    
        def get_config_from_remote
          if engine_version < Gem::Version.new("1.4.14")
            data = remote_command(OLD_CONFIG_COMMAND)
          else
            data = remote_command(CONFIG_COMMAND)
          end
          ConfigResponse.new(data)
        end
      
        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def remote_command(command)
          socket = tcp_socket(@host, @port, @timeout)
          socket.puts command
        
          data = ""
          until (line = socket.readline) =~ /END/
            data << line
          end
        
          socket.close
          data
        end

        # Creates and connects a tcp socket with an optional timeout
        #
        # Returns a Socket or TCPSocket instance
        def tcp_socket(host, port, timeout)
          if timeout.nil?
            TCPSocket.new(host, port)
          else
            # Convert the passed host into structures the non-blocking calls
            # can deal with
            addr = Socket.getaddrinfo(host, nil)
            sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

            Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
              socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

              begin
                # Initiate the socket connection in the background. If it doesn't fail
                # immediatelyit will raise an IO::WaitWritable (Errno::EINPROGRESS)
                # indicating the connection is in progress.
                socket.connect_nonblock(sockaddr)

              rescue IO::WaitWritable
                # IO.select will block until the socket is writable or the timeout
                # is exceeded - whichever comes first.
                if IO.select(nil, [socket], nil, timeout)
                  begin
                    # Verify there is now a good connection
                    socket.connect_nonblock(sockaddr)
                  rescue Errno::EISCONN
                    return socket
                      # Good news everybody, the socket is connected!
                  rescue
                    # An unexpected exception was raised - the connection is no good.
                    socket.close
                    raise
                  end
                else
                  # IO.select returns nil when the socket is not ready before timeout
                  # seconds have elapsed
                  socket.close
                  raise Timeout, "Connection attempt took longer than timeout of #{timeout} seconds"
                end
              end
            end
          end
        end
      end
    end
  end
end
