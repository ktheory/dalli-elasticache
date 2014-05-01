Dalli ElastiCache
=================
[![Gem Version](https://badge.fury.io/rb/dalli-elasticache.svg)](http://badge.fury.io/rb/dalli-elasticache) [![Code Climate](https://codeclimate.com/github/ktheory/dalli-elasticache.png)](https://codeclimate.com/github/ktheory/dalli-elasticache) [![Build Status](https://travis-ci.org/zmillman/dalli-elasticache.svg?branch=request-refactor)](https://travis-ci.org/zmillman/dalli-elasticache)

A wrapper for configuring [Dalli memcached clients](https://github.com/mperham/dalli)
from [AWS ElastiCache Auto Discovery](http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html).

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
config_endpoint = "my-cluster-name.abc123.cfg.use1.cache.amazonaws.com:1211"
elasticache     = Dalli::ElastiCache.new(endpoint)

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
# => #<Dalli::Client ... @servers=["10.84.227.155:11211", ...]>

# Node IP addresses and hostnames
elasticache.servers
# => ["10.84.227.115:11211", "10.77.71.127:11211"]

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
