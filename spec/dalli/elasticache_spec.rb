require 'spec_helper'

describe Dalli::ElastiCache do
  before do
    @tcp_socket_mock = mock "tcp socket"
    @elasticache = Dalli::ElastiCache.new "host.cfg.use1.cache.amazonaws.com:11211",
                                          :expires_in => 3600, :namespace => "my_app"
    TCPSocket.should_receive(:new).
              with('host.cfg.use1.cache.amazonaws.com', "11211").
              and_return @tcp_socket_mock
    @tcp_socket_mock.should_receive(:puts).with("config get cluster\r\n")
    output = "mycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\r\n"
    @tcp_socket_mock.should_receive(:gets).
                     and_return("CONFIG cluster 0 78", "1", "#{output}\r\n", "END\r\n")
    @tcp_socket_mock.should_receive(:close)
  end

  it "should return the servers for a given elasticache" do
    @elasticache.servers.should == ["10.112.21.1:11211", "10.112.21.2:11211", "10.112.21.3:11211"]
  end

  it "should return the version for a given elasticache" do
    @elasticache.version.should == 1
  end

  it "should refresh the data" do
    @elasticache.refresh.should == @elasticache
  end

  it "should return a dalli client with the given servers" do
    client = @elasticache.client
    client.instance_variable_get(:@servers).
           should == ["10.112.21.1:11211", "10.112.21.2:11211", "10.112.21.3:11211"]
  end

end
