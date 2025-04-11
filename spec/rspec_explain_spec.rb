# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RspecExplain do
  it "has a version number" do
    expect(RspecExplain::VERSION).not_to be nil
  end

  describe "custom matcher" do
    # This example uses a fake ActiveRecord model structure for testing
    # In a real app, you would use your actual models
    
    let(:model_class) do
      # Mock an ActiveRecord class that would return explain output indicating a full table scan
      Class.new do
        def self.explain
          if instance_variable_defined?(:@use_index)
            # Simulate index scan
            "Limit  (cost=0.28..8.29 rows=1 width=617) (actual time=0.019..0.019 rows=0 loops=1)\n" +
            "  ->  Index Scan using index_users_on_email on users"
          else
            # Simulate full table scan
            "Limit  (cost=0.28..8.29 rows=1 width=617) (actual time=0.019..0.019 rows=0 loops=1)\n" +
            "  ->  Seq Scan on users"
          end
        end
        
        def self.use_index
          @use_index = true
          self
        end
      end
    end
    
    it "raises FullScanError for queries that would perform full table scans" do
      expect(model_class).to raise_full_scan_error
    end
    
    it "doesn't raise FullScanError for queries that use indexes" do
      expect(model_class.use_index).not_to raise_full_scan_error
    end
  end
end
