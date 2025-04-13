# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RspecExplain do
  it "has a version number" do
    expect(RspecExplain::VERSION).not_to be nil
  end

  describe "full scan matchers" do
    describe "original raise_full_scan_error" do
      it "raises FullScanError for queries that would perform full table scans" do
        # A query that will cause a full table scan (no index on 'name')
        query = User.where("name = 'User One'")
        expect(query).to raise_full_scan_error
      end
      
      it "doesn't raise FullScanError for queries that use indexes" do
        # A query that will use the index we created on 'email'
        query = User.where(email: 'user1@example.com')
        expect(query).not_to raise_full_scan_error
      end
      
      it "raises FullScanError for OR conditions that combine indexed and non-indexed columns" do
        # A query that uses OR with one indexed and one non-indexed column
        # MySQL optimizer often can't use indexes effectively with OR
        query = User.where("email = 'user1@example.com' OR name = 'User One'")
        expect(query).to raise_full_scan_error
      end
      
      it "raises FullScanError for LIKE queries without proper index use" do
        # A query with a LIKE that starts with wildcard, preventing index use
        query = User.where("email LIKE '%example.com'")
        expect(query).to raise_full_scan_error
      end
      
      it "doesn't raise FullScanError for LIKE queries that can use an index" do
        # A query with a LIKE that doesn't start with wildcard, can use index
        query = User.where("email LIKE 'user1%'")
        expect(query).not_to raise_full_scan_error
      end
    end

    describe "alternative detect_full_table_scan" do
      it "detects full table scans" do
        # A query that will cause a full table scan (no index on 'name')
        query = User.where("name = 'User One'")
        expect(query).to detect_full_table_scan
      end
      
      it "doesn't detect full table scans when using indexes" do
        # A query that will use the index we created on 'email'
        query = User.where(email: 'user1@example.com')
        expect(query).not_to detect_full_table_scan
      end
    end
  end
  
  describe "access type matcher" do
    it "detects problematic access types" do
      # A query that will use ALL access type (full table scan)
      query = User.where("name = 'User One'")
      expect(query).not_to have_good_access_type
      
      # A query that will use a better access type (ref)
      query = User.where(email: 'user1@example.com')
      expect(query).to have_good_access_type
    end
  end
  
  describe "row count matcher" do
    it "checks if query scans too many rows" do
      # Our test database has only a few rows, so all queries should pass
      query = User.where("name = 'User One'")
      expect(query).to scan_fewer_than(10)
      
      # But we can test the failure case with a very low threshold
      expect(query).not_to scan_fewer_than(1)
    end
  end
  
  describe "expensive operation matcher" do
    it "detects expensive operations" do
      # A simple query without filesort or temporary tables
      query = User.where(email: 'user1@example.com')
      expect(query).to avoid_expensive_operations
      
      # A query with ORDER BY on a non-indexed column should use filesort
      query = User.all.order('name ASC')
      expect(query).not_to avoid_expensive_operations
    end
  end
  
  describe "index usage matcher" do
    it "checks if query uses an index" do
      # A query that uses the index on email
      query = User.where(email: 'user1@example.com')
      expect(query).to use_index
      
      # A query that doesn't use any index
      query = User.where("name = 'User One'")
      expect(query).not_to use_index
    end
  end
  
  describe "available index matcher" do
    it "checks if query uses available index candidates" do
      # A query that uses an index properly
      query = User.where(email: 'user1@example.com')
      expect(query).to use_available_indexes
      
      # A query with a potential index, but force not to use it
      # This is a bit artificial but works for testing
      query = User.where("email = 'user1@example.com' OR name = 'User One'")
      expect(query).not_to use_available_indexes
    end
  end
  
  describe "combined usage example" do
    context "with a poorly optimized query" do
      let(:query) { User.where("name = 'User One'") }
      
      it "fails multiple optimizations checks" do
        # Check if it uses a full table scan
        expect(query).to raise_full_scan_error
        
        # Check if it uses a bad access type
        expect(query).not_to have_good_access_type
        
        # Check if it uses an index
        expect(query).not_to use_index
      end
    end
    
    context "with an optimized query" do
      let(:query) { User.where(email: 'user1@example.com') }
      
      it "passes optimization checks" do
        # Check if query doesn't trigger a full table scan
        expect(query).not_to raise_full_scan_error
        
        # Check if it uses a good access type
        expect(query).to have_good_access_type
        
        # Check if it scans few enough rows
        expect(query).to scan_fewer_than(10)
        
        # Check if it avoids expensive operations
        expect(query).to avoid_expensive_operations
        
        # Check if it uses an index
        expect(query).to use_index
        
        # Check if it uses available index candidates
        expect(query).to use_available_indexes
      end
    end
  end
end
