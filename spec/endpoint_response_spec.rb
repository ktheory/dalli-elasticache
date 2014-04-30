require_relative 'spec_helper'

describe 'Dalli::ElastiCacheConfigResponse' do
  let :response do
    text = <<-EOS
12\r\n
mycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\r\n
    EOS
    Dalli::ElastiCacheConfigResponse.new(text)
  end
  
  describe '#version' do
    it 'parses version' do
      response.version.should == 12
    end
  end

  describe '#nodes' do
    it 'parses hosts' do
      response.nodes.map{|s| s[:host]}.should == [
        "mycluster.0001.cache.amazonaws.com",
        "mycluster.0002.cache.amazonaws.com",
        "mycluster.0003.cache.amazonaws.com"
      ]
    end
  
    it 'parses ip addresses' do
      response.nodes.map{|s| s[:ip]}.should == ["10.112.21.1", "10.112.21.2", "10.112.21.3"]
    end
  
    it 'parses ports' do
      response.nodes.map{|s| s[:port]}.should == [11211, 11211, 11211]
    end
  end
end
