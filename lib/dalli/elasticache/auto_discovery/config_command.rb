# frozen_string_literal: true

module Dalli
  module Elasticache
    module AutoDiscovery
      ##
      # Encapsulates execution of the 'config' command, which is used to
      # extract the list of nodes and determine if that list of nodes has changed.
      ##
      class ConfigCommand < BaseCommand
        attr_reader :engine_version

        CONFIG_COMMAND = "config get cluster\r\n"

        # Legacy command for version < 1.4.14
        LEGACY_CONFIG_COMMAND = "get AmazonElastiCache:cluster\r\n"

        def initialize(host, port, engine_version)
          super(host, port)
          @engine_version = engine_version
        end

        def response
          ConfigResponse.new(send_command)
        end

        def command
          return LEGACY_CONFIG_COMMAND if legacy_config?

          CONFIG_COMMAND
        end

        def legacy_config?
          return false unless engine_version
          return false if engine_version == 'unknown'

          Gem::Version.new(engine_version) < Gem::Version.new('1.4.14')
        rescue ArgumentError
          # Just assume false if we can't parse the engine_version
          false
        end
      end
    end
  end
end
