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
          explain_result = query.explain
          scan_type = extract_scan_type(explain_result)
          
          # If the query isn't using indexes, it's a full scan
          full_scan = full_scan?(scan_type)
          
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
          "expected the query to raise RspecExplain::FullScanError but it used indexes"
        end
      end
      
      def failure_message_when_negated
        "expected the query not to raise RspecExplain::FullScanError, but it did"
      end
      
      private
      
      def extract_scan_type(explain_result)
        # This is database-specific and would need to be adapted based on the database
        # PostgreSQL: Look for 'Seq Scan' vs 'Index Scan'
        # MySQL: Look for 'ALL' vs 'ref', 'range', etc.
        # SQLite: Look for 'SCAN TABLE' vs 'SEARCH TABLE'
        
        # For ActiveRecord >= 6.0, use format: :hash for MySQL to get structured EXPLAIN
        if defined?(ActiveRecord) && 
           ActiveRecord::VERSION::MAJOR >= 6 && 
           ActiveRecord::Base.connection.adapter_name.downcase == 'mysql2'
          begin
            # Try with format: :hash first which returns a structured hash
            explain_hash = ActiveRecord::Base.connection.explain(explain_result, analyze: true)
            # Convert hash to string for easier pattern matching
            return explain_hash.to_s.downcase
          rescue
            # Fall back to default behavior if explain with hash format fails
          end
        end
        
        explain_result.to_s.downcase
      end
      
      def full_scan?(scan_type)
        # PostgreSQL
        return true if scan_type.include?('seq scan') && !scan_type.include?('index scan')
        
        # MySQL - Better MySQL detection with more specific patterns
        return true if scan_type.include?('type: all') || 
                       scan_type.include?('select type: simple') && scan_type.include?('type: all') ||
                       scan_type.include?('using where; full table scan')
        
        # SQLite
        return true if scan_type.include?('scan table') && !scan_type.include?('search table')
        
        false
      end
    end
  end
end

RSpec.configure do |config|
  config.include RspecExplain::Matchers
end
