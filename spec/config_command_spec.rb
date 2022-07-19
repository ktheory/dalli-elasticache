# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::ConfigCommand' do
  let(:host) { Faker::Internet.domain_name(subdomain: true) }
  let(:port) { rand(1024..16_023) }
  let(:command) { Dalli::Elasticache::AutoDiscovery::ConfigCommand.new(host, port, engine_version) }

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

  let(:mock_socket) { instance_double(TCPSocket) }

  before do
    allow(TCPSocket).to receive(:new).with(host, port).and_return(mock_socket)
    allow(mock_socket).to receive(:close)
    allow(mock_socket).to receive(:puts).with(cmd)
    allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
  end

  context 'when the engine_version is 1.4.5' do
    let(:engine_version) { '1.4.5' } # This is the only pre-1.4.14 version available on AWS
    let(:cmd) { Dalli::Elasticache::AutoDiscovery::ConfigCommand::LEGACY_CONFIG_COMMAND }

    context 'when the socket returns a valid response' do
      before do
        allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
      end

      it 'sends the legacy command and returns a ConfigResponse with expected values' do
        response = command.response
        expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
        expect(response.version).to eq(12)
        expect(response.nodes).to eq(expected_nodes)
        expect(mock_socket).to have_received(:close)
      end
    end
  end

  context 'when the engine_version is greater than or equal to 1.4.14' do
    let(:engine_version) { ['1.4.14', '1.5.6', '1.6.10'].sample }
    let(:cmd) { Dalli::Elasticache::AutoDiscovery::ConfigCommand::CONFIG_COMMAND }

    context 'when the socket returns a valid response' do
      before do
        allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
      end

      it 'sends the current command and returns a ConfigResponse with expected values' do
        response = command.response
        expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
        expect(response.version).to eq(12)
        expect(response.nodes).to eq(expected_nodes)
        expect(mock_socket).to have_received(:close)
      end
    end
  end

  context 'when the engine_version is UNKNOWN or some other string' do
    let(:engine_version) { ['UNKNOWN', SecureRandom.hex(4), nil].sample }
    let(:cmd) { Dalli::Elasticache::AutoDiscovery::ConfigCommand::CONFIG_COMMAND }

    context 'when the socket returns a valid response' do
      before do
        allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
      end

      it 'sends the current command and returns a ConfigResponse with expected values' do
        response = command.response
        expect(response).to be_a Dalli::Elasticache::AutoDiscovery::ConfigResponse
        expect(response.version).to eq(12)
        expect(response.nodes).to eq(expected_nodes)
        expect(mock_socket).to have_received(:close)
      end
    end
  end
end
