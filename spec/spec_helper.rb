require "bundler/setup"

require "dalli/elasticache"
require "active_support/cache/dalli_elasticache_store"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
  config.mock_with :rspec do |c|
    c.syntax = :should
  end
end
