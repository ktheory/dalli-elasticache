# dalli-elasticache

A wrapper for the [Dalli memcached client](https://github.com/mperham/dalli) with support for [AWS ElastiCache Auto Discovery](http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html)

## Installation

Install the [rubygem](https://rubygems.org/gems/dalli-elasticache):

    # in your Gemfile
    gem 'dalli-elasticache'

## Usage

### Using ElastiCache with Rails 3.x and newer:

    # in config/environments/production.rb
    elasticache = Dalli::ElastiCache.new(config_endpoint)
    config.cache_store = :dalli_store, elasticache.servers, {:expires_in => 1.day, :compress => true}

Note that the ElastiCache server list will be refreshed each time an app server process starts.

### General client usage:

    # Create an ElastiCache instance with your config endpoint and options for Dalli
    elasticache = Dalli::ElastiCache.new(config_endpoint, dalli_options={})
    # For example:
    elasticache = Dalli::ElastiCache.new("aaron-scratch.vfdnac.cfg.use1.cache.amazonaws.com:11211", :expires_in => 3600, :namespace => "my_app")

    elasticache.version # => the config version returned by the ElastiCache config endpoint.

    elasticache.servers # => array of IP addresses and hostnames, e.g. ["10.84.227.115:11211", "10.77.71.127:11211"]

    client = elasticache.client # a regular Dalli::Client using the instance IP addresses returns by the config endpoint

    # Check the endpoint to see if the version has changed:
    elasticache.refresh.version
    # If so, update your dalli client:
    client = elasticache.client

## License

Copyright 2013 Aaron Suggs

Released under an [MIT License](http://opensource.org/licenses/MIT)
