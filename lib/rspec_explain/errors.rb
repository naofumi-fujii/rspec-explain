# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

module RspecExplain
  extend T::Sig
  
  class FullScanError < StandardError
    extend T::Sig
    
    sig { params(msg: String).void }
    def initialize(msg = "Query would perform a full table scan")
      super
    end
  end
  
  class BadTypeError < StandardError
    extend T::Sig
    
    sig { params(msg: String).void }
    def initialize(msg = "Query uses a problematic access type (ALL or index)")
      super
    end
  end
  
  class TooManyRowsError < StandardError
    extend T::Sig
    
    sig { returns(Integer) }
    attr_reader :rows
    
    sig { returns(Integer) }
    attr_reader :threshold
    
    sig { params(rows: Integer, threshold: Integer, msg: T.nilable(String)).void }
    def initialize(rows, threshold, msg = nil)
      @rows = rows
      @threshold = threshold
      super(msg || "Query would scan too many rows (#{rows} > threshold of #{threshold})")
    end
  end
  
  class ExpensiveOperationError < StandardError
    extend T::Sig
    
    sig { returns(T::Array[String]) }
    attr_reader :operations
    
    sig { params(operations: T::Array[String], msg: T.nilable(String)).void }
    def initialize(operations, msg = nil)
      @operations = operations
      super(msg || "Query uses expensive operations: #{operations.join(', ')}")
    end
  end
  
  class NoIndexError < StandardError
    extend T::Sig
    
    sig { params(msg: String).void }
    def initialize(msg = "Query does not use an available index")
      super
    end
  end
  
  class UnusedIndexCandidateError < StandardError
    extend T::Sig
    
    sig { returns(String) }
    attr_reader :possible_keys
    
    sig { params(possible_keys: String, msg: T.nilable(String)).void }
    def initialize(possible_keys, msg = nil)
      @possible_keys = possible_keys
      super(msg || "Query has potential indexes (#{possible_keys}) but none were used")
    end
  end
end
