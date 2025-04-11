# frozen_string_literal: true

module RspecExplain
  class FullScanError < StandardError
    def initialize(msg = "Query would perform a full table scan")
      super
    end
  end
  
  class BadTypeError < StandardError
    def initialize(msg = "Query uses a problematic access type (ALL or index)")
      super
    end
  end
  
  class TooManyRowsError < StandardError
    def initialize(rows, threshold, msg = nil)
      @rows = rows
      @threshold = threshold
      super(msg || "Query would scan too many rows (#{rows} > threshold of #{threshold})")
    end
  end
  
  class ExpensiveOperationError < StandardError
    def initialize(operations, msg = nil)
      @operations = operations
      super(msg || "Query uses expensive operations: #{operations.join(', ')}")
    end
  end
  
  class NoIndexError < StandardError
    def initialize(msg = "Query does not use an available index")
      super
    end
  end
  
  class UnusedIndexCandidateError < StandardError
    def initialize(possible_keys, msg = nil)
      @possible_keys = possible_keys
      super(msg || "Query has potential indexes (#{possible_keys}) but none were used")
    end
  end
end
