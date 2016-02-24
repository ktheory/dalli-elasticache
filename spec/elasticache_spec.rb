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

  let(:config_text) { "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n" }
  let(:response) { Dalli::Elasticache::AutoDiscovery::ConfigResponse.new(config_text) }

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
    before { Dalli::Elasticache::AutoDiscovery::Endpoint.any_instance.should_receive(:get_config_from_remote).and_return(response) }

    it 'lists addresses and ports' do
      cache.servers.should == ["mycluster.0001.cache.amazonaws.com:11211", "mycluster.0002.cache.amazonaws.com:11211", "mycluster.0003.cache.amazonaws.com:11211"]
    end
  end
  
  describe '#version' do
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
