# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::StatsCommand' do
  let(:host) { 'example.com' }
  let(:port) { 12_345 }
  let(:command) { Dalli::Elasticache::AutoDiscovery::StatsCommand.new(host, port) }
  let(:engine_version) { ['1.4.5', '1.4.14', '1.5.6', '1.6.10'].sample }
  let(:cmd) { "stats\r\n" }

  let(:socket_response_lines) do
    [
      "STAT pid 1\r\n",
      "STAT uptime 68717\r\n",
      "STAT time 1398885375\r\n",
      "STAT version #{engine_version}\r\n",
      "STAT libevent 1.4.13-stable\r\n",
      "STAT pointer_size 64\r\n",
      "STAT rusage_user 0.136008\r\n",
      "STAT rusage_system 0.424026\r\n",
      "STAT curr_connections 5\r\n",
      "STAT total_connections 1159\r\n",
      "STAT connection_structures 6\r\n",
      "STAT reserved_fds 5\r\n",
      "STAT cmd_get 0\r\n",
      "STAT cmd_set 0\r\n",
      "STAT cmd_flush 0\r\n",
      "STAT cmd_touch 0\r\n",
      "STAT cmd_config_get 4582\r\n",
      "STAT cmd_config_set 2\r\n",
      "STAT get_hits 0\r\n",
      "STAT get_misses 0\r\n",
      "STAT delete_misses 0\r\n",
      "STAT delete_hits 0\r\n",
      "STAT incr_misses 0\r\n",
      "STAT incr_hits 0\r\n",
      "STAT decr_misses 0\r\n",
      "STAT decr_hits 0\r\n",
      "STAT cas_misses 0\r\n",
      "STAT cas_hits 0\r\n",
      "STAT cas_badval 0\r\n",
      "STAT touch_hits 0\r\n",
      "STAT touch_misses 0\r\n",
      "STAT auth_cmds 0\r\n",
      "STAT auth_errors 0\r\n",
      "STAT bytes_read 189356\r\n",
      "STAT bytes_written 2906615\r\n",
      "STAT limit_maxbytes 209715200\r\n",
      "STAT accepting_conns 1\r\n",
      "STAT listen_disabled_num 0\r\n",
      "STAT threads 1\r\n",
      "STAT conn_yields 0\r\n",
      "STAT curr_config 1\r\n",
      "STAT hash_power_level 16\r\n",
      "STAT hash_bytes 524288\r\n",
      "STAT hash_is_expanding 0\r\n",
      "STAT expired_unfetched 0\r\n",
      "STAT evicted_unfetched 0\r\n",
      "STAT bytes 0\r\n",
      "STAT curr_items 0\r\n",
      "STAT total_items 0\r\n",
      "STAT evictions 0\r\n",
      "STAT reclaimed 0\r\n",
      "END\r\n"
    ]
  end

  let(:mock_socket) { instance_double(TCPSocket) }

  before do
    allow(TCPSocket).to receive(:new).with(host, port).and_return(mock_socket)
    allow(mock_socket).to receive(:close)
    allow(mock_socket).to receive(:puts).with(cmd)
    allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
  end

  context 'when the socket returns a valid response' do
    before do
      allow(mock_socket).to receive(:readline).and_return(*socket_response_lines)
    end

    it 'sends the command and parses out the engine version' do
      response = command.response
      expect(response.engine_version).to eq(engine_version)
      expect(mock_socket).to have_received(:close)
      expect(mock_socket).to have_received(:puts).with(cmd)
    end
  end
end
