require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::Endpoint' do
  let(:endpoint) do
    Dalli::Elasticache::AutoDiscovery::Endpoint.new("my-cluster.cfg.use1.cache.amazonaws.com:11211", nil)
  end
  
  describe '.new' do
    it 'parses host' do
      endpoint.host.should == "my-cluster.cfg.use1.cache.amazonaws.com"
    end
    it 'parses port' do
      endpoint.port.should == 11211
    end
  end
end
