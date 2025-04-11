# frozen_string_literal: true

module RspecExplain
  class FullScanError < StandardError
    def initialize(msg = "Query would perform a full table scan")
      super
    end
  end
end
