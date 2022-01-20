# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Encapsulates execution of the 'stats' command, which is used to
      # extract the engine_version
      ##
      class StatsCommand < BaseCommand
        STATS_COMMAND = "stats\r\n"

        def response
          StatsResponse.new(send_command)
        end

        def command
          STATS_COMMAND
        end
      end
    end
  end
end
