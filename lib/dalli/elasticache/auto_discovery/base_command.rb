# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Base command class for configuration endpoint
      # command.  Contains the network logic.
      ##
      class BaseCommand
        attr_reader :host, :port, :timeout

        def initialize(host, port, timeout = nil)
          @host = host
          @port = port
          @timeout = timeout
        end

        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def send_command
          socket = ::Socket.tcp(@host, @port, connect_timeout: timeout)
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

        def wait_for_data(socket)
          return unless timeout

          raise Timeout::Error, "Auto discovery read timed out after #{timeout}s" unless socket.wait_readable(timeout)
        end
      end
    end
  end
end
