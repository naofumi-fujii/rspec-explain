# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RspecExplain do
  it "has a version number" do
    expect(RspecExplain::VERSION).not_to be nil
  end

  describe "with real ActiveRecord" do
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
end
