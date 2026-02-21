# frozen_string_literal: true

require 'openssl'

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Base command class for configuration endpoint
      # command.  Contains the network logic.
      ##
      class BaseCommand
        attr_reader :host, :port, :timeout, :ssl_context

        def initialize(host, port, timeout = nil, ssl_context: nil)
          @host = host
          @port = port
          @timeout = timeout
          @ssl_context = ssl_context
        end

        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def send_command
          tcp_socket = ::Socket.tcp(@host, @port, connect_timeout: timeout)
          socket = ssl_context ? wrap_with_ssl(tcp_socket) : tcp_socket
          begin
            socket.puts command
            response_from_socket(socket)
          ensure
            socket.close
          end
        end

        def response_from_socket(socket)
          data = +''
          loop do
            wait_for_data(socket)
            line = socket.readline
            break if line.include?('END')

            data << line
          end

          data
        end

        private

        def wrap_with_ssl(tcp_socket)
          ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
          ssl_socket.hostname = @host
          ssl_socket.sync_close = true
          ssl_socket.connect
          ssl_socket
        end

        def wait_for_data(socket)
          return unless timeout

          raise Timeout::Error, "Auto discovery read timed out after #{timeout}s" unless socket.wait_readable(timeout)
        end
      end
    end
  end
end
