require_relative 'spec_helper'

describe 'ActiveSupport::Cache::DalliElasticacheStore' do

  describe '#new' do
    it 'responds to #new' do
      ActiveSupport::Cache::DalliElasticacheStore.respond_to?(:new).should == true
    end

    it 'inherits from DalliStore' do
      ActiveSupport::Cache::DalliElasticacheStore.ancestors.include?(ActiveSupport::Cache::DalliStore).should == true
    end
  end

end
