Dalli ElastiCache [![Gem Version](https://badge.fury.io/rb/dalli-elasticache.svg)](http://badge.fury.io/rb/dalli-elasticache) [![Build Status](https://github.com/ktheory/dalli-elasticache/actions/workflows/tests.yml/badge.svg)](https://github.com/ktheory/dalli-elasticache/actions/workflows/tests.yml) [![Code Climate](https://codeclimate.com/github/ktheory/dalli-elasticache.png)](https://codeclimate.com/github/ktheory/dalli-elasticache)
=================

Use [AWS ElastiCache AutoDiscovery](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/AutoDiscovery.html) or [Google Cloud MemoryStore Auto Discovery](https://cloud.google.com/memorystore/docs/memcached/using-auto-discovery) to automatically configure your [Dalli memcached client](https://github.com/petergoldstein/dalli) with all the nodes in your cluster.

Installation
------------

Install the [gem](https://rubygems.org/gems/dalli-elasticache):

```ruby
# in your Gemfile
gem 'dalli-elasticache'
```

Using Dalli Elasticache in Rails
---------------------------------

Note that the list of memcached servers used by Rails will be refreshed each time an app server process starts.  If the list of nodes in your cluster changes, this configuration will not be reflected in the Rails configuraiton without such a server process restart.

### Configuring a Cache Store

The most common use of Dalli in Rails is to support a cache store.  To set up your cache store with a cluster, you'll need to generate the list of servers with Dalli ElastiCache and pass them to the `cache_store` configuration.  This needs to be done in your `config/environments/RAILS_ENV.rb` file for each Rails environment where you want to use a cluster.

```ruby
# in config/environments/production.rb
endpoint    = "my-cluster-name.abc123.cfg.use1.cache.amazonaws.com:11211"
elasticache = Dalli::ElastiCache.new(endpoint)

config.cache_store = :mem_cache_store, elasticache.servers, { expires_in: 1.day }
```
### Configuring a Session Store

Another use of Dalli in Rails is to support a Rails session store.  Dalli ElastiCache can also be used in this case.  The usage is very similar - first use Dalli ElastiCache to generate the list of servers, and then pass that result to the Rails configuration.  In `config/application.rb` you would write:

```ruby
# in config/environments/production.rb
endpoint    = "my-cluster-name.abc123.cfg.use1.cache.amazonaws.com:11211"
elasticache = Dalli::ElastiCache.new(endpoint)

config.session_store = :mem_cache_store, memcache_server: elasticache.servers, pool_size: 10, pool_timeout: 5, expire_after: 1.day
```

### Dalli Considerations

Please see [here](https://github.com/petergoldstein/dalli/wiki/Using-Dalli-with-Rails) for more information on configuring Dalli and Rails.


Using Dalli ElastiCache with a Dalli Client
------------

To initialize a Dalli Client for all the nodes of a cluster, one simply needs to pass the configuration endpoint and any options for the Dalli Client into the `Dalli::ElastiCache` initializer. Then one can use the methods on the `Dalli::ElastiCache` object to generate an appropriately configured `Dalli::Client`or to get information about the cluster.

```ruby
config_endpoint = "aaron-scratch.vfdnac.cfg.use1.cache.amazonaws.com:11211"

# Options for configuring the Dalli::Client
dalli_options = {
  expires_in: 24 * 60 * 60,
  namespace: "my_app"
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

Copyright (2017-2022) Aaron Suggs, Peter M. Goldstein. See LICENSE for details.
