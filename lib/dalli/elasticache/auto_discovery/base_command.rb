# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Base command class for configuration endpoint
      # command.  Contains the network logic.
      ##
      class BaseCommand
        attr_reader :host, :port

        def initialize(host, port)
          @host = host
          @port = port
        end

        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def send_command
          socket = TCPSocket.new(@host, @port)
          begin
            socket.puts command
            response_from_socket(socket)
          ensure
            socket.close
          end
        end

        def response_from_socket(socket)
          data = +''
          until (line = socket.readline).include?('END')
            data << line
          end

          data
        end
      end
    end
  end
end
