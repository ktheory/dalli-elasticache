require_relative 'spec_helper'

describe 'Dalli::ElastiCacheEndpointResponse' do
  
  describe 'with multi-node response' do
    let :response do
      text = <<-EOS
      CONFIG cluster 0 141
      2
      magoosh-dev.5qkuaz.0001.use1.cache.amazonaws.com|10.154.181.156|11211 magoosh-dev.5qkuaz.0002.use1.cache.amazonaws.com|10.154.182.29|11211

      END
      EOS
      Dalli::ElastiCacheEndpointResponse.new(text)
    end
  
    describe '#version' do
      it 'parses version' do
        response.version.should == "0"
      end
    end
  
    describe '#nodes' do
      it 'parses hosts' do
        response.nodes.map{|s| s[:host]}.should == [
          "magoosh-dev.5qkuaz.0001.use1.cache.amazonaws.com",
          "magoosh-dev.5qkuaz.0002.use1.cache.amazonaws.com"
        ]
      end
    
      it 'parses ip addresses' do
        response.nodes.map{|s| s[:ip]}.should == ["10.154.181.156", "10.154.182.29"]
      end
    
      it 'parses ports' do
        response.nodes.map{|s| s[:port]}.should == [11211, 11211]
      end
    end
  end
end