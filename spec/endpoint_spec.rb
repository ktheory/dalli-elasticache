require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::Endpoint' do
  subject { Dalli::Elasticache::AutoDiscovery::Endpoint.new(endpoint) }

  describe '.new' do
    context 'endpoint specifies port' do
      let(:endpoint) { "my-cluster.cfg.use1.cache.amazonaws.com:11211" }

      it 'parses host' do
        subject.host.should == "my-cluster.cfg.use1.cache.amazonaws.com"
      end
      it 'parses port' do
        subject.port.should == 11211
      end
    end
    context 'endpoint is plain url (no port)' do
      let(:endpoint) { "my-cluster.cfg.use1.cache.amazonaws.com" }

      it 'raises ArgumentError' do
        -> { subject }.should raise_error(ArgumentError)
      end
    end
  end
end
