require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::Endpoint' do
  subject(:endpoint) { Dalli::Elasticache::AutoDiscovery::Endpoint.new endpoint_str }

  describe '.new' do
    context 'host and port specified' do
      let(:endpoint_str) { "my-cluster.cfg.use1.cache.amazonaws.com:12345" }
      its(:host) { should eq 'my-cluster.cfg.use1.cache.amazonaws.com' }
      its(:port) { should eq 12345 }
    end

    context 'only host specified' do
      let(:endpoint_str) { 'test.example.com' }
      its(:host) { should eq 'test.example.com' }
      its(:port) { should eq 11211 }
    end
  end
end
