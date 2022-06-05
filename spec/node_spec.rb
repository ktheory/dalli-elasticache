# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::Node' do
  context 'when comparing with equals' do
    let(:host1) { Faker::Internet.domain_name(subdomain: true) }
    let(:ip1) { Faker::Internet.public_ip_v4_address }
    let(:port1) { rand(1024..16_023) }
    let(:host2) { Faker::Internet.domain_name(subdomain: true) }
    let(:ip2) { Faker::Internet.public_ip_v4_address }
    let(:port2) { rand(1024..16_023) }

    let(:node1a) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port1) }
    let(:node1b) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port1) }

    let(:node_with_different_host) { Dalli::Elasticache::AutoDiscovery::Node.new(host2, ip1, port1) }
    let(:node_with_different_ip) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip2, port1) }
    let(:node_with_different_port) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port2) }

    it 'is equal to a value with the same values' do
      expect(node1a).to eq(node1b)
      expect(node1a.eql?(node1b)).to be(true)
    end

    it 'is not equal to a value with any differing values' do
      expect(node1a).not_to eq(node_with_different_host)
      expect(node1a.eql?(node_with_different_host)).to be(false)
      expect(node1a).not_to eq(node_with_different_ip)
      expect(node1a.eql?(node_with_different_ip)).to be(false)
      expect(node1a).not_to eq(node_with_different_port)
      expect(node1a.eql?(node_with_different_port)).to be(false)
    end
  end

  context 'when used as a hash key' do
    let(:host1) { Faker::Internet.domain_name(subdomain: true) }
    let(:ip1) { Faker::Internet.public_ip_v4_address }
    let(:port1) { rand(1024..16_023) }
    let(:host2) { Faker::Internet.domain_name(subdomain: true) }
    let(:ip2) { Faker::Internet.public_ip_v4_address }
    let(:port2) { rand(1024..16_023) }

    let(:node1a) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port1) }
    let(:node1b) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port1) }

    let(:node_with_different_host) { Dalli::Elasticache::AutoDiscovery::Node.new(host2, ip1, port1) }
    let(:node_with_different_ip) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip2, port1) }
    let(:node_with_different_port) { Dalli::Elasticache::AutoDiscovery::Node.new(host1, ip1, port2) }

    let(:test_val) { 'abcd' }
    let(:test_hash) do
      { node1a => test_val }
    end

    it 'computes the same hash key' do
      expect(node1a.hash).to eq(node1b.hash)
    end

    it 'matches when an equivalent object is used' do
      expect(test_hash.key?(node1b)).to be(true)
    end

    it 'does not match when an non-equivalent object is used' do
      expect(test_hash.key?(node_with_different_host)).to be(false)
      expect(test_hash.key?(node_with_different_ip)).to be(false)
      expect(test_hash.key?(node_with_different_port)).to be(false)
    end
  end

  describe '#to_s' do
    let(:host) { Faker::Internet.domain_name(subdomain: true) }
    let(:ip) { Faker::Internet.public_ip_v4_address }
    let(:port) { rand(1024..16_023) }

    let(:node) { Dalli::Elasticache::AutoDiscovery::Node.new(host, ip, port) }

    it 'returns the expected string value' do
      expect(node.to_s).to eq("#{host}:#{port}")
    end
  end
end
