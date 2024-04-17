require 'dalli-elasticache'
require 'active_support/cache/dalli_store'

module ActiveSupport
  module Cache
    class DalliElasticacheStore < DalliStore
      def initialize(*endpoint_and_options)
        endpoint, *options = endpoint_and_options
        elasticache = Dalli::ElastiCache.new(endpoint)
        super(elasticache.servers, options)
      end
    end
  end
end

