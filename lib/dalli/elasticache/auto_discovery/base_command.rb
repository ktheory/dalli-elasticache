# frozen_string_literal: true

require 'openssl'
require 'timeout'

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
          begin
            socket = ssl_context ? wrap_with_ssl(tcp_socket) : tcp_socket
            socket.puts command
            response_from_socket(socket)
          ensure
            (socket || tcp_socket).close
          end
        end

        # `timeout` bounds the entire multi-line read as a single wall-clock deadline,
        # not each individual `readline`. A per-line readiness check (e.g. `wait_readable`)
        # can't tell buffered-but-unread bytes apart from an empty socket once a buffering
        # layer (Ruby's IO buffer, or OpenSSL::Buffering for TLS) sits between the fd and
        # `readline`, so it can't be used to gate individual lines reliably.
        def response_from_socket(socket)
          return read_lines(socket) unless timeout

          Timeout.timeout(timeout, Timeout::Error, "Auto discovery read timed out after #{timeout}s") do
            read_lines(socket)
          end
        end

        private

        def read_lines(socket)
          data = +''
          loop do
            line = socket.readline
            break if line.include?('END')

            data << line
          end
          data
        end

        def wrap_with_ssl(tcp_socket)
          ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
          ssl_socket.hostname = @host
          ssl_socket.sync_close = true
          ssl_socket.connect
          ssl_socket
        end
      end
    end
  end
end
