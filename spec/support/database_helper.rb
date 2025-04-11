# frozen_string_literal: true

require 'yaml'
require 'active_record'

module DatabaseHelper
  def self.establish_connection
    config = YAML.load_file(File.join(__dir__, 'database.yml'))['test']
    ActiveRecord::Base.establish_connection(config)
  end

  def self.setup_database
    establish_connection
    
    # Create a User model for testing
    unless Object.const_defined?(:User)
      Object.const_set(:User, Class.new(ActiveRecord::Base) do
        self.table_name = 'users'
      end)
    end
  end
end