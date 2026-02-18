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
end
