# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::Endpoint' do
  let(:endpoint) do
    Dalli::Elasticache::AutoDiscovery::Endpoint.new(arg_string)
  end

  describe '.new' do
    context 'when the string includes both host and port' do
      let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:12345' }

      it 'parses host' do
        expect(endpoint.host).to eq 'my-cluster.cfg.use1.cache.amazonaws.com'
      end

      it 'parses port' do
        expect(endpoint.port).to eq 12_345
      end
    end

    context 'when the string includes both only a host' do
      let(:arg_string) { 'example.cfg.use1.cache.amazonaws.com' }

      it 'parses host' do
        expect(endpoint.host).to eq 'example.cfg.use1.cache.amazonaws.com'
      end

      it 'parses port' do
        expect(endpoint.port).to eq 11_211
      end
    end

    context 'when the string is nil' do
      let(:arg_string) { nil }

      it 'raises ArgumentError' do
        expect do
          endpoint
        end.to raise_error ArgumentError, "Unable to parse configuration endpoint address - #{arg_string}"
      end
    end

    context 'when the string contains disallowed characters in the host' do
      let(:arg_string) { 'my-cluster?.cfg.use1.cache.amazonaws.com:12345' }

      it 'raises ArgumentError' do
        expect do
          endpoint
        end.to raise_error ArgumentError, "Unable to parse configuration endpoint address - #{arg_string}"
      end
    end

    context 'when the string contains disallowed characters in the port' do
      let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:1234a5' }

      it 'raises ArgumentError' do
        expect do
          endpoint
        end.to raise_error ArgumentError, "Unable to parse configuration endpoint address - #{arg_string}"
      end
    end

    context 'when the string contains trailing characters' do
      let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:12345abcd' }

      it 'raises ArgumentError' do
        expect do
          endpoint
        end.to raise_error ArgumentError, "Unable to parse configuration endpoint address - #{arg_string}"
      end
    end
  end
end
