# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::ConfigCommand' do
  let(:host) { Faker::Internet.domain_name(subdomain: true) }
  let(:port) { rand(1024..16_023) }
  let(:command) { Dalli::Elasticache::AutoDiscovery::ConfigCommand.new(host, port) }

  let(:socket_response_lines) do
    [
      "CONFIG cluster 0 142\r\n",
      "12\r\n",
      'mycluster.0001.cache.amazonaws.com|10.112.21.1|11211 ' \
      'mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 ' \
      "mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\r\n",
      "\r\n",
      "END\r\n"
    ]
  end

  let(:expected_nodes) do
    [
      Dalli::Elasticache::AutoDiscovery::Node.new('mycluster.0001.cache.amazonaws.com',
                                                  '10.112.21.1',
                                                  11_211),
      Dalli::Elasticache::AutoDiscovery::Node.new('mycluster.0002.cache.amazonaws.com',
                                                  '10.112.21.2',
                                                  11_211),
      Dalli::Elasticache::AutoDiscovery::Node.new('mycluster.0003.cache.amazonaws.com',
                                                  '10.112.21.3',
                                                  11_211)
    ]
  end

  let(:mock_socket) { instance_double(Socket) }

  before do
    allow(Socket).to receive(:tcp).with(host, port, connect_timeout: nil).and_return(mock_socket)
    allow(mock_socket).to receive(:close)
    allow(mock_socket).to receive(:puts).with(Dalli::Elasticache::AutoDiscovery::ConfigCommand::CONFIG_COMMAND)
    allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
  end

  it 'sends the config command and returns a ConfigResponse with expected values' do
    response = command.response
    expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
    expect(response.version).to eq(12)
    expect(response.nodes).to eq(expected_nodes)
    expect(mock_socket).to have_received(:close)
  end

  context 'with a read timeout' do
    let(:command) { Dalli::Elasticache::AutoDiscovery::ConfigCommand.new(host, port, read_timeout) }

    before do
      allow(Socket).to receive(:tcp).with(host, port, connect_timeout: read_timeout).and_return(mock_socket)
    end

    context 'when all lines are read before the timeout elapses' do
      let(:read_timeout) { 5 }

      it 'returns a ConfigResponse' do
        response = command.response
        expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
        expect(response.version).to eq(12)
        expect(response.nodes).to eq(expected_nodes)
      end
    end

    context 'when the read does not complete before the timeout elapses' do
      let(:read_timeout) { 0.01 }

      before do
        allow(mock_socket).to receive(:readline) do
          sleep 0.05
          socket_response_lines.first
        end
      end

      it 'raises Timeout::Error' do
        expect { command.response }.to raise_error(Timeout::Error, /timed out after 0.01s/)
      end
    end
  end

  context 'when an ssl_context is provided' do
    let(:ssl_context) { instance_double(OpenSSL::SSL::SSLContext) }
    let(:command) { Dalli::Elasticache::AutoDiscovery::ConfigCommand.new(host, port, nil, ssl_context:) }
    let(:mock_ssl_socket) { instance_double(OpenSSL::SSL::SSLSocket) }

    before do
      allow(OpenSSL::SSL::SSLSocket).to receive(:new).with(mock_socket, ssl_context).and_return(mock_ssl_socket)
      allow(mock_ssl_socket).to receive(:hostname=).with(host)
      allow(mock_ssl_socket).to receive(:sync_close=).with(true)
      allow(mock_ssl_socket).to receive(:connect)
      allow(mock_ssl_socket).to receive(:close)
      allow(mock_ssl_socket).to receive(:puts).with(Dalli::Elasticache::AutoDiscovery::ConfigCommand::CONFIG_COMMAND)
      allow(mock_ssl_socket).to receive(:readline).and_return(*socket_response_lines)
    end

    it 'wraps the TCP socket with SSL and returns a ConfigResponse' do
      response = command.response
      expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
      expect(response.version).to eq(12)
      expect(response.nodes).to eq(expected_nodes)
      expect(OpenSSL::SSL::SSLSocket).to have_received(:new).with(mock_socket, ssl_context)
      expect(mock_ssl_socket).to have_received(:connect)
      expect(mock_ssl_socket).to have_received(:close)
    end

    context 'with a timeout' do
      let(:command) { Dalli::Elasticache::AutoDiscovery::ConfigCommand.new(host, port, 5, ssl_context:) }

      before do
        allow(Socket).to receive(:tcp).with(host, port, connect_timeout: 5).and_return(mock_socket)
      end

      # The fix for #65 replaced per-line readiness gating (SSLSocket#pending / wait_readable)
      # with a Timeout.timeout deadline around the whole read, so this code path never calls
      # pending or wait_readable at all. Leaving both unstubbed on this instance_double means
      # the test fails if either is ever invoked, proving that.
      it 'returns a ConfigResponse without polling socket readiness between lines' do
        response = command.response
        expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
        expect(response.version).to eq(12)
        expect(response.nodes).to eq(expected_nodes)
      end
    end
  end
end
