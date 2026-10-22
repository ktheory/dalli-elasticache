# frozen_string_literal: true

require 'ipaddr'
require 'openssl'
require 'timeout'

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Raised when the configuration endpoint replies with ERROR,
      # CLIENT_ERROR, or SERVER_ERROR instead of the expected response.
      ##
      class ResponseError < StandardError; end

      ##
      # Base command class for configuration endpoint
      # command.  Contains the network logic.
      ##
      class BaseCommand
        attr_reader :host, :port, :timeout, :ssl_context

        END_LINE = "END\r\n"
        ERROR_LINE_REGEX = /\A(?:ERROR|CLIENT_ERROR|SERVER_ERROR)\b/

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
          tcp_socket = ::Socket.tcp(socket_host, @port, connect_timeout: timeout)
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
          with_timeout('read') { read_lines(socket) }
        end

        private

        def with_timeout(phase, &)
          return yield unless timeout

          Timeout.timeout(timeout, Timeout::Error, "Auto discovery #{phase} timed out after #{timeout}s", &)
        end

        # The host without the brackets used to delimit an IPv6 address from its port
        def socket_host
          @host.delete_prefix('[').delete_suffix(']')
        end

        def ip_address?(host)
          IPAddr.new(host)
          true
        rescue IPAddr::InvalidAddressError
          false
        end

        def read_lines(socket)
          data = +''
          loop do
            line = socket.readline
            break if line == END_LINE
            raise ResponseError, "Auto discovery command failed: #{line.strip}" if ERROR_LINE_REGEX.match?(line)

            data << line
          end
          data
        end

        def wrap_with_ssl(tcp_socket)
          ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
          # SNI must be a DNS name (RFC 6066), never an IP literal
          ssl_socket.hostname = socket_host unless ip_address?(socket_host)
          ssl_socket.sync_close = true
          # connect_timeout only covers the TCP connect, so bound the handshake separately
          with_timeout('TLS handshake') { ssl_socket.connect }
          verify_hostname(ssl_socket)
          ssl_socket
        end

        # SSLContext.new leaves verify_hostname false, so VERIFY_PEER alone only checks
        # that the certificate chains to a trusted CA, not that it was issued for this
        # host. Check the hostname explicitly whenever the peer is being verified.
        def verify_hostname(ssl_socket)
          return if ssl_context.verify_mode.to_i.nobits?(OpenSSL::SSL::VERIFY_PEER)

          ssl_socket.post_connection_check(socket_host)
        end
      end
    end
  end
end
