# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::ConfigResponse' do
  let :response do
    text = "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 "\
           'mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 '\
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
      expect(response.nodes.map { |s| s[:host] }).to eq [
        'mycluster.0001.cache.amazonaws.com',
        'mycluster.0002.cache.amazonaws.com',
        'mycluster.0003.cache.amazonaws.com'
      ]
    end

    it 'parses ip addresses' do
      expect(response.nodes.map { |s| s[:ip] }).to eq ['10.112.21.1', '10.112.21.2', '10.112.21.3']
    end

    it 'parses ports' do
      expect(response.nodes.map { |s| s[:port] }).to eq [11_211, 11_211, 11_211]
    end
  end
end
