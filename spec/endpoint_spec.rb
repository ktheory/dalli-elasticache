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

    context 'when the string includes only a host' do
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

    context 'when the host in the string includes an underscore' do
      let(:arg_string) { 'my_cluster.cfg.use1.cache.amazonaws.com:12345' }

      it 'parses host' do
        expect(endpoint.host).to eq 'my_cluster.cfg.use1.cache.amazonaws.com'
      end

      it 'parses port' do
        expect(endpoint.port).to eq 12_345
      end
    end

    context 'when the string is a bracketed IPv6 address with port' do
      let(:arg_string) { '[2001:db8::1]:11211' }

      it 'parses host' do
        expect(endpoint.host).to eq '[2001:db8::1]'
      end

      it 'parses port' do
        expect(endpoint.port).to eq 11_211
      end
    end

    context 'when the string is a bracketed IPv6 address without port' do
      let(:arg_string) { '[::1]' }

      it 'parses host' do
        expect(endpoint.host).to eq '[::1]'
      end

      it 'parses port' do
        expect(endpoint.port).to eq 11_211
      end
    end

    context 'when the string contains a newline' do
      let(:arg_string) { "injected\nmy-cluster.cfg.use1.cache.amazonaws.com:11211" }

      it 'raises ArgumentError' do
        expect { endpoint }.to raise_error ArgumentError, /Unable to parse configuration endpoint address/
      end
    end

    context 'when the string has a trailing newline' do
      let(:arg_string) { "my-cluster.cfg.use1.cache.amazonaws.com:11211\n" }

      it 'raises ArgumentError' do
        expect { endpoint }.to raise_error ArgumentError, /Unable to parse configuration endpoint address/
      end
    end

    [0, 65_536, 999_999].each do |bad_port|
      context "when the port is #{bad_port}" do
        let(:arg_string) { "my-cluster.cfg.use1.cache.amazonaws.com:#{bad_port}" }

        it 'raises ArgumentError' do
          expect { endpoint }.to raise_error ArgumentError, /port must be between 1 and 65535/
        end
      end
    end

    context 'when the port is 65535' do
      let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:65535' }

      it 'parses port' do
        expect(endpoint.port).to eq 65_535
      end
    end
  end

  describe 'timeout' do
    let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:11211' }
    let(:mock_command) { instance_double(Dalli::Elasticache::AutoDiscovery::ConfigCommand, response: nil) }

    before do
      allow(Dalli::Elasticache::AutoDiscovery::ConfigCommand).to receive(:new).and_return(mock_command)
    end

    it 'defaults to 5 seconds when not given' do
      endpoint.config
      expect(Dalli::Elasticache::AutoDiscovery::ConfigCommand).to have_received(:new)
        .with('my-cluster.cfg.use1.cache.amazonaws.com', 11_211, 5, ssl_context: nil)
    end

    it 'can be disabled explicitly with nil' do
      Dalli::Elasticache::AutoDiscovery::Endpoint.new(arg_string, timeout: nil).config
      expect(Dalli::Elasticache::AutoDiscovery::ConfigCommand).to have_received(:new)
        .with('my-cluster.cfg.use1.cache.amazonaws.com', 11_211, nil, ssl_context: nil)
    end
  end

  describe '#config' do
    let(:arg_string) { 'my-cluster.cfg.use1.cache.amazonaws.com:11211' }
    let(:mock_command) { instance_double(Dalli::Elasticache::AutoDiscovery::ConfigCommand) }
    let(:config_response) { Dalli::Elasticache::AutoDiscovery::ConfigResponse.new("CONFIG cluster 0 4\r\n12\r\n") }

    before do
      allow(Dalli::Elasticache::AutoDiscovery::ConfigCommand).to receive(:new).and_return(mock_command)
      allow(mock_command).to receive(:response) do
        sleep 0.1
        config_response
      end
    end

    it 'runs the config command once when called concurrently' do
      results = Array.new(5) { Thread.new { endpoint.config } }.map(&:value)
      expect(results).to all(be(config_response))
      expect(mock_command).to have_received(:response).once
    end
  end
end
