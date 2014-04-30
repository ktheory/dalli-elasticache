require_relative 'spec_helper'

describe 'Dalli::Elasticache::AutoDiscovery::StatsResponse' do
  let :response do
    text = "STAT pid 1\r\nSTAT uptime 68717\r\nSTAT time 1398885375\r\nSTAT version 1.4.14\r\nSTAT libevent 1.4.13-stable\r\nSTAT pointer_size 64\r\nSTAT rusage_user 0.136008\r\nSTAT rusage_system 0.424026\r\nSTAT curr_connections 5\r\nSTAT total_connections 1159\r\nSTAT connection_structures 6\r\nSTAT reserved_fds 5\r\nSTAT cmd_get 0\r\nSTAT cmd_set 0\r\nSTAT cmd_flush 0\r\nSTAT cmd_touch 0\r\nSTAT cmd_config_get 4582\r\nSTAT cmd_config_set 2\r\nSTAT get_hits 0\r\nSTAT get_misses 0\r\nSTAT delete_misses 0\r\nSTAT delete_hits 0\r\nSTAT incr_misses 0\r\nSTAT incr_hits 0\r\nSTAT decr_misses 0\r\nSTAT decr_hits 0\r\nSTAT cas_misses 0\r\nSTAT cas_hits 0\r\nSTAT cas_badval 0\r\nSTAT touch_hits 0\r\nSTAT touch_misses 0\r\nSTAT auth_cmds 0\r\nSTAT auth_errors 0\r\nSTAT bytes_read 189356\r\nSTAT bytes_written 2906615\r\nSTAT limit_maxbytes 209715200\r\nSTAT accepting_conns 1\r\nSTAT listen_disabled_num 0\r\nSTAT threads 1\r\nSTAT conn_yields 0\r\nSTAT curr_config 1\r\nSTAT hash_power_level 16\r\nSTAT hash_bytes 524288\r\nSTAT hash_is_expanding 0\r\nSTAT expired_unfetched 0\r\nSTAT evicted_unfetched 0\r\nSTAT bytes 0\r\nSTAT curr_items 0\r\nSTAT total_items 0\r\nSTAT evictions 0\r\nSTAT reclaimed 0\r\n"
    Dalli::Elasticache::AutoDiscovery::StatsResponse.new(text)
  end
  
  describe '#version' do
    it 'parses version' do
      response.version.should == Gem::Version.new("1.4.14")
    end
  end
end
