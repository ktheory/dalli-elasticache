# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::ElastiCache::Endpoint' do
  let(:dalli_options) do
    {
      expires_in: 24 * 60 * 60,
      namespace: 'my_app',
      compress: true
    }
  end

  let(:host) { 'my-cluster.cfg.use1.cache.amazonaws.com' }
  let(:port) { 11_211 }
  let(:config_endpoint) { "#{host}:#{port}" }
  let(:cache) do
    Dalli::ElastiCache.new(config_endpoint, dalli_options)
  end

  let(:config_text) do
    "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 " \
      'mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 ' \
      "mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n"
  end
  let(:response) { Dalli::Elasticache::AutoDiscovery::ConfigResponse.new(config_text) }

  describe '.new' do
    it 'builds endpoint' do
      expect(cache.endpoint.host).to eq 'my-cluster.cfg.use1.cache.amazonaws.com'
      expect(cache.endpoint.port).to eq 11_211
    end

    it 'stores Dalli options' do
      expect(cache.options[:expires_in]).to eq 24 * 60 * 60
      expect(cache.options[:namespace]).to eq 'my_app'
      expect(cache.options[:compress]).to be true
    end
  end

  describe '#client' do
    let(:client) { cache.client }
    let(:stub_endpoint) { Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint) }
    let(:mock_dalli) { instance_double(Dalli::Client) }

    before do
      allow(Dalli::Elasticache::AutoDiscovery::Endpoint).to receive(:new)
        .with(config_endpoint, timeout: Dalli::ElastiCache::DEFAULT_TIMEOUT).and_return(stub_endpoint)
      allow(stub_endpoint).to receive(:config).and_return(response)
      allow(Dalli::Client).to receive(:new)
        .with(['mycluster.0001.cache.amazonaws.com:11211',
               'mycluster.0002.cache.amazonaws.com:11211',
               'mycluster.0003.cache.amazonaws.com:11211'],
              dalli_options).and_return(mock_dalli)
    end

    it 'builds with node list and dalli options' do
      expect(client).to eq(mock_dalli)
      expect(stub_endpoint).to have_received(:config)
      expect(Dalli::Client).to have_received(:new)
        .with(['mycluster.0001.cache.amazonaws.com:11211',
               'mycluster.0002.cache.amazonaws.com:11211',
               'mycluster.0003.cache.amazonaws.com:11211'],
              dalli_options)
    end
  end

  describe '#servers' do
    let(:stub_endpoint) { Dalli::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint) }

    before do
      allow(Dalli::Elasticache::AutoDiscovery::Endpoint).to receive(:new)
        .with(config_endpoint, timeout: Dalli::ElastiCache::DEFAULT_TIMEOUT).and_return(stub_endpoint)
      allow(stub_endpoint).to receive(:config).and_return(response)
    end

    it 'lists addresses and ports' do
      expect(cache.servers).to eq ['mycluster.0001.cache.amazonaws.com:11211',
                                   'mycluster.0002.cache.amazonaws.com:11211',
                                   'mycluster.0003.cache.amazonaws.com:11211']
      expect(stub_endpoint).to have_received(:config)
      expect(Dalli::Elasticache::AutoDiscovery::Endpoint).to have_received(:new)
        .with(config_endpoint, timeout: Dalli::ElastiCache::DEFAULT_TIMEOUT)
    end
  end

  describe '#version' do
    let(:mock_config) { instance_double(Dalli::Elasticache::AutoDiscovery::ConfigResponse) }
    let(:version) { rand(1..20) }

    before do
      allow(cache.endpoint).to receive(:config).and_return(mock_config)
      allow(mock_config).to receive(:version).and_return(version)
    end

    it 'delegates the call to the config on the endpoint' do
      expect(cache.version).to eq(version)
      expect(cache.endpoint).to have_received(:config)
      expect(mock_config).to have_received(:version)
    end
  end

  describe '#engine_version' do
    let(:engine_version) { [Gem::Version.new('1.6.13'), Gem::Version.new('1.4.14')].sample }

    before do
      allow(cache.endpoint).to receive(:engine_version).and_return(engine_version)
    end

    it 'delegates the call to the endpoint' do
      expect(cache.engine_version).to eq(engine_version)
      expect(cache.endpoint).to have_received(:engine_version)
    end
  end

  describe '#refresh' do
    it 'clears endpoint configuration' do
      stale_endpoint = cache.endpoint
      expect(cache.refresh.endpoint).not_to eq stale_endpoint
    end

    it 'builds endpoint with same configuration' do
      stale_endpoint = cache.endpoint
      cache.refresh
      expect(cache.endpoint.host).to eq(stale_endpoint.host)
      expect(cache.endpoint.port).to eq(stale_endpoint.port)
    end
  end
end
