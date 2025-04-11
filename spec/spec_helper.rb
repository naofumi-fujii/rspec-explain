# frozen_string_literal: true

require "rspec_explain"
require "active_record"
require_relative "support/database_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  
  config.before(:suite) do
    # Use ENV var to check if we should connect to the real database
    if ENV["USE_REAL_DB"] == "true"
      DatabaseHelper.setup_database
    end
  end
end
