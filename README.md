Dalli ElastiCache [![Gem Version](https://badge.fury.io/rb/dalli-elasticache.svg)](http://badge.fury.io/rb/dalli-elasticache) [![Build Status](https://travis-ci.org/ktheory/dalli-elasticache.svg)](https://travis-ci.org/ktheory/dalli-elasticache) [![Code Climate](https://codeclimate.com/github/ktheory/dalli-elasticache.png)](https://codeclimate.com/github/ktheory/dalli-elasticache)
=================

Use [AWS ElastiCache AutoDiscovery](http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html) to automatically configure your [Dalli memcached client](https://github.com/mperham/dalli) with all the nodes in your cluster.

Installation
------------

Install the [rubygem](https://rubygems.org/gems/dalli-elasticache):

```ruby
# in your Gemfile
gem 'dalli-elasticache'
```

Setup for Rails 3.x and Newer
-----------------------------

Configure your environment-specific application settings:

```ruby
# in config/environments/production.rb
endpoint    = "my-cluster-name.abc123.cfg.use1.cache.amazonaws.com:11211"
elasticache = Dalli::ElastiCache.new(endpoint)

config.cache_store = :dalli_store, elasticache.servers, {:expires_in => 1.day, :compress => true}
```

Note that the ElastiCache server list will be refreshed each time an app server process starts.

Client Usage
------------

Create an ElastiCache instance:

```ruby
config_endpoint = "aaron-scratch.vfdnac.cfg.use1.cache.amazonaws.com:11211"

# Options for configuring the Dalli::Client
dalli_options = {
  :expires_in => 24 * 60 * 60,
  :namespace => "my_app",
  :compress => true
}

elasticache = Dalli::ElastiCache.new(config_endpoint, dalli_options)
```

Fetch information about the Memcached nodes:

```ruby
# Dalli::Client with configuration from the AutoDiscovery endpoint
elasticache.client
# => #<Dalli::Client ... @servers=["aaron-scratch.vfdnac.0001.use1.cache.amazonaws.com:11211", ...]>

# Node addresses
elasticache.servers
# => ["aaron-scratch.vfdnac.0001.use1.cache.amazonaws.com:11211", "aaron-scratch.vfdnac.0002.use1.cache.amazonaws.com:11211"]

# Number of times the cluster configuration has changed
elasticache.version
# => 12

# Memcached version of the cluster
elasticache.engine_version
# => "1.4.14"

# Refresh data from the endpoint
elasticache.refresh

# Refresh and get client with new configuration
elasticache.refresh.client
```

License
-------

Copyright 2013 Aaron Suggs

Released under an [MIT License](http://opensource.org/licenses/MIT)
