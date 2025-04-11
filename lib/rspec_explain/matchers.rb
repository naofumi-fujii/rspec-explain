# frozen_string_literal: true

require "rspec/expectations"

module RspecExplain
  module Matchers
    # Checks if an ActiveRecord query would use an index or perform a full table scan
    def raise_full_scan_error
      FullScanMatcher.new
    end
    
    class FullScanMatcher
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
  end
end

RSpec.configure do |config|
  config.include RspecExplain::Matchers
end
