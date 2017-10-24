require_relative 'spec_helper'

describe 'Dalli::ElastiCache::Endpoint' do
  let(:cache) do
    options = {
      :expires_in => 24*60*60,
      :namespace => "my_app",
      :compress => true
    }
    Dalli::ElastiCache.new("my-cluster.cfg.use1.cache.amazonaws.com:11211", options)
  end
  
  describe '.new' do
    it 'builds endpoint' do
      cache.endpoint.host.should == "my-cluster.cfg.use1.cache.amazonaws.com"
      cache.endpoint.port.should == 11211
    end
    
    it 'stores Dalli options' do
      cache.options[:expires_in].should == 24*60*60
      cache.options[:namespace].should == "my_app"
      cache.options[:compress].should == true
    end
  end
  
  describe '#client' do
    it 'builds with node list'
    it 'builds with options'
  end
  
  describe '#servers' do
    it 'lists addresses and ports'
  end
  
  describe '#version' do
    it 'has constant defined' do
      defined?(Dalli::ElastiCache::VERSION).should == 'constant'
    end
  end
  
  describe '#engine_version' do
  end
  
  describe '#refresh' do
    it 'clears endpoint configuration' do
      stale_endpoint = cache.endpoint
      cache.refresh.endpoint.should_not === stale_endpoint
    end
    
    it 'builds endpoint with same configuration' do
      stale_endpoint = cache.endpoint
      cache.refresh
      cache.endpoint.host.should == stale_endpoint.host
      cache.endpoint.port.should == stale_endpoint.port
    end
  end
  
end
