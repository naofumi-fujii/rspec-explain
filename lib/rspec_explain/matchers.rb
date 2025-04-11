# frozen_string_literal: true

require "rspec/expectations"

module RspecExplain
  module Matchers
    # Checks if an ActiveRecord query would use an index or perform a full table scan
    def raise_full_scan_error
      FullScanMatcher.new
    end
    
    # Checks if query has problematic access type (ALL or index)
    def have_good_access_type
      AccessTypeMatcher.new
    end
    
    # Checks if query scans too many rows
    def scan_fewer_than(threshold)
      RowCountMatcher.new(threshold)
    end
    
    # Checks if query uses expensive operations like filesort or temporary tables
    def avoid_expensive_operations
      ExpensiveOperationMatcher.new
    end
    
    # Checks if query uses an index
    def use_index
      IndexUsageMatcher.new
    end
    
    # Checks if query uses available index candidates
    def use_available_indexes
      AvailableIndexMatcher.new
    end
    
    # Common base class for all explain matchers
    class BaseMatcher
      def initialize
        @query = nil
        @explain_result = nil
        @explain_rows = nil
        @error = nil
        @specific_error = nil
      end
      
      def matches?(query)
        begin
          # Save the query for debugging
          @query = query
          
          # Get the EXPLAIN output
          @explain_result = query.explain
          
          # Get the raw EXPLAIN data if possible
          connection = ActiveRecord::Base.connection
          sql = @query.to_sql
          @explain_rows = connection.exec_query("EXPLAIN #{sql}").to_a
          
          # Call the specific matcher implementation
          # This might raise an error if the test should fail
          check_explain
          
          # No error raised means test should pass
          true
        rescue RspecExplain::FullScanError, 
               RspecExplain::BadTypeError, 
               RspecExplain::TooManyRowsError,
               RspecExplain::ExpensiveOperationError,
               RspecExplain::NoIndexError,
               RspecExplain::UnusedIndexCandidateError => e
          @specific_error = e
          false # Matcher error means test fails
        rescue => e
          @error = e
          false # Other errors mean the test fails
        end
      end
      
      # Template method to be implemented by subclasses
      def check_explain
        raise NotImplementedError, "Subclasses must implement check_explain"
      end
      
      def failure_message
        if @error
          "expected the query to pass but got unexpected error: #{@error.message}"
        elsif @specific_error
          "expected the query to pass but failed: #{@specific_error.message}\n" +
          "Query: #{@query.to_sql}\n" +
          "EXPLAIN output: #{@explain_result}"
        else
          "expected the query to pass but it failed\n" +
          "Query: #{@query.to_sql}\n" +
          "EXPLAIN output: #{@explain_result}"
        end
      end
      
      def failure_message_when_negated
        "expected the query to fail, but it passed\n" +
        "Query: #{@query.to_sql}\n" +
        "EXPLAIN output: #{@explain_result}"
      end
      
      # Helper to get MySQL EXPLAIN rows (falls back to parsing explain_result text)
      def mysql_explain_rows
        if @explain_rows && !@explain_rows.empty?
          return @explain_rows
        end
        
        # Fallback - try to parse from text output
        []
      end
    end
    
    class FullScanMatcher
      def initialize
        @query = nil
        @explain_result = nil
        @error = nil
      end
      
      def matches?(query)
        begin
          # Save the query for debugging
          @query = query
          
          # Get the EXPLAIN output
          explain_result = query.explain
          @explain_result = explain_result
          
          # Determine if it's a full scan
          full_scan = full_scan?(explain_result)
          
          if full_scan
            raise RspecExplain::FullScanError
          end
          
          false # Match means an error was raised
        rescue RspecExplain::FullScanError
          true # Match successful
        rescue => e
          @error = e
          false # Other errors mean the match failed
        end
      end
      
      def failure_message
        if @error
          "expected the query to raise RspecExplain::FullScanError but got: #{@error.message}"
        else
          "expected the query to raise RspecExplain::FullScanError but it used indexes\n" +
          "Query: #{@query.to_sql}\n" +
          "EXPLAIN output: #{@explain_result}"
        end
      end
      
      def failure_message_when_negated
        "expected the query not to raise RspecExplain::FullScanError, but it did\n" +
        "Query: #{@query.to_sql}\n" +
        "EXPLAIN output: #{@explain_result}"
      end
      
      private
      
      def full_scan?(explain_result)
        # First, normalize and identify the database type
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        # MySQL-specific detection logic
        if adapter_type == 'mysql2'
          # Try to parse the EXPLAIN output directly
          explain_text = explain_result.to_s.downcase
          
          if explain_text.include?("type=all") || explain_text.include?("type: all")
            return true
          end
          
          # For more complex cases, try to get the raw EXPLAIN data
          begin
            sql = @query.to_sql
            explain_rows = connection.exec_query("EXPLAIN #{sql}").to_a
            
            # Check for ALL type which indicates full table scan
            explain_rows.each do |row|
              if row["type"] == "ALL"
                return true
              end
            end
          rescue => e
            # If we can't get the raw explain data, fall back to string parsing
            if explain_text.include?("full table scan") || 
               explain_text.include?("filesort") ||
               explain_text.include?("temporary table")
              return true
            end
          end
        
        # PostgreSQL-specific detection logic 
        elsif adapter_type == 'postgresql'
          explain_text = explain_result.to_s.downcase
          if explain_text.include?('seq scan') && !explain_text.include?('index scan')
            return true
          end
        
        # SQLite-specific detection logic
        elsif adapter_type == 'sqlite'
          explain_text = explain_result.to_s.downcase
          if explain_text.include?('scan table') && !explain_text.include?('search table')
            return true
          end
        
        # Generic fallback logic
        else
          explain_text = explain_result.to_s.downcase
          if explain_text.include?('full scan') || 
             explain_text.include?('table scan') ||
             explain_text.include?('seq scan')
            return true
          end
        end
        
        # If we got here, it's not a full table scan
        false
      end
    end
    
    class AccessTypeMatcher < BaseMatcher
      def check_explain
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        if adapter_type == 'mysql2'
          rows = mysql_explain_rows
          
          rows.each do |row|
            if row["type"] == "ALL" || row["type"] == "index"
              raise RspecExplain::BadTypeError
            end
          end
        else
          # For other databases, rely on existing full scan detection
          # since we're mainly looking for the same issue
          explain_text = @explain_result.to_s.downcase
          
          if explain_text.include?('full scan') || 
             explain_text.include?('table scan') ||
             explain_text.include?('seq scan') ||
             explain_text.include?('index scan')
            raise RspecExplain::BadTypeError
          end
        end
      end
    end
    
    class RowCountMatcher < BaseMatcher
      def initialize(threshold)
        super()
        @threshold = threshold
      end
      
      def check_explain
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        if adapter_type == 'mysql2'
          rows = mysql_explain_rows
          
          rows.each do |row|
            if row["rows"] && row["rows"].to_i > @threshold
              raise RspecExplain::TooManyRowsError.new(row["rows"].to_i, @threshold)
            end
          end
        end
        # For other databases, we might need to implement specific logic
        # for extracting row counts from EXPLAIN output
      end
    end
    
    class ExpensiveOperationMatcher < BaseMatcher
      def check_explain
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        if adapter_type == 'mysql2'
          rows = mysql_explain_rows
          expensive_operations = []
          
          rows.each do |row|
            if row["Extra"]
              if row["Extra"].include?("Using filesort")
                expensive_operations << "Using filesort"
              end
              
              if row["Extra"].include?("Using temporary")
                expensive_operations << "Using temporary"
              end
            end
          end
          
          if expensive_operations.any?
            raise RspecExplain::ExpensiveOperationError.new(expensive_operations)
          end
        else
          # For other databases, we'd implement specific detection
          # for expensive operations in their EXPLAIN format
          explain_text = @explain_result.to_s.downcase
          if explain_text.include?('sort') || explain_text.include?('temp')
            raise RspecExplain::ExpensiveOperationError.new(["Sort or temporary operations"])
          end
        end
      end
    end
    
    class IndexUsageMatcher < BaseMatcher
      def check_explain
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        if adapter_type == 'mysql2'
          rows = mysql_explain_rows
          
          rows.each do |row|
            if row["key"].nil? || row["key"] == "NULL"
              raise RspecExplain::NoIndexError
            end
          end
        else
          # For other databases, rely on existing full scan detection
          # since we're mainly checking for index usage
          check_explain_like_full_scan
        end
      end
      
      def check_explain_like_full_scan
        # First, normalize and identify the database type
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        # PostgreSQL-specific detection logic 
        if adapter_type == 'postgresql'
          explain_text = @explain_result.to_s.downcase
          if explain_text.include?('seq scan') && !explain_text.include?('index scan')
            raise RspecExplain::NoIndexError
          end
        
        # SQLite-specific detection logic
        elsif adapter_type == 'sqlite'
          explain_text = @explain_result.to_s.downcase
          if explain_text.include?('scan table') && !explain_text.include?('search table')
            raise RspecExplain::NoIndexError
          end
        
        # Generic fallback logic
        else
          explain_text = @explain_result.to_s.downcase
          if explain_text.include?('full scan') || 
             explain_text.include?('table scan') ||
             explain_text.include?('seq scan')
            raise RspecExplain::NoIndexError
          end
        end
      end
    end
    
    class AvailableIndexMatcher < BaseMatcher
      def check_explain
        connection = ActiveRecord::Base.connection
        adapter_type = connection.adapter_name.downcase
        
        if adapter_type == 'mysql2'
          rows = mysql_explain_rows
          
          rows.each do |row|
            if (row["key"].nil? || row["key"] == "NULL") && 
               row["possible_keys"] && row["possible_keys"] != "NULL"
              raise RspecExplain::UnusedIndexCandidateError.new(row["possible_keys"])
            end
          end
        end
        # For other databases, we might need to implement specific logic
        # to detect unused index candidates
      end
    end
  end
end

RSpec.configure do |config|
  config.include RspecExplain::Matchers
end
