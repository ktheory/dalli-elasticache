# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Encapsulates execution of the 'config' command, which is used to
      # extract the list of nodes and determine if that list of nodes has changed.
      ##
      class ConfigCommand < BaseCommand
        CONFIG_COMMAND = "config get cluster\r\n"

        def response
          ConfigResponse.new(send_command)
        end

        def command
          CONFIG_COMMAND
        end
      end
    end
  end
end
