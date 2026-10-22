# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::ConfigResponse' do
  let :response do
    text = "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 " \
           'mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 ' \
           "mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n"
    Dalli::Elasticache::AutoDiscovery::ConfigResponse.new(text)
  end

  describe '#version' do
    it 'parses version' do
      expect(response.version).to eq 12
    end
  end

  describe '#nodes' do
    it 'parses hosts' do
      expect(response.nodes.map(&:host)).to eq [
        'mycluster.0001.cache.amazonaws.com',
        'mycluster.0002.cache.amazonaws.com',
        'mycluster.0003.cache.amazonaws.com'
      ]
    end

    it 'parses ip addresses' do
      expect(response.nodes.map(&:ip)).to eq ['10.112.21.1', '10.112.21.2', '10.112.21.3']
    end

    it 'parses ports' do
      expect(response.nodes.map(&:port)).to eq [11_211, 11_211, 11_211]
    end

    def response_for(node_list)
      Dalli::Elasticache::AutoDiscovery::ConfigResponse.new("CONFIG cluster 0 100\r\n3\r\n#{node_list}\r\n\r\n")
    end

    context 'when the cluster reports IPv6 addresses' do
      let(:response) do
        response_for('mycluster.0001.cache.amazonaws.com|2600:1f18:a2b:c300::10|11211 ' \
                     'mycluster.0002.cache.amazonaws.com|2600:1f18:a2b:c300::11|11211')
      end

      it 'parses the nodes' do
        expect(response.nodes.map(&:to_s)).to eq ['mycluster.0001.cache.amazonaws.com:11211',
                                                  'mycluster.0002.cache.amazonaws.com:11211']
        expect(response.nodes.map(&:ip)).to eq ['2600:1f18:a2b:c300::10', '2600:1f18:a2b:c300::11']
      end
    end

    context 'when a node has no IP address' do
      let(:response) { response_for('mycluster.0001.cache.amazonaws.com||11211') }

      it 'parses the node with an empty IP' do
        expect(response.nodes).to eq [
          Dalli::Elasticache::AutoDiscovery::Node.new('mycluster.0001.cache.amazonaws.com', '', 11_211)
        ]
      end
    end

    context 'when a hostname contains an underscore' do
      let(:response) { response_for('my_cluster.0001.cache.amazonaws.com|10.112.21.1|11211') }

      it 'parses the node' do
        expect(response.nodes.map(&:to_s)).to eq ['my_cluster.0001.cache.amazonaws.com:11211']
      end
    end
  end
end
