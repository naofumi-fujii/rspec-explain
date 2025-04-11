# frozen_string_literal: true

require 'yaml'
require 'active_record'
require 'logger'

module DatabaseHelper
  def self.establish_connection
    config = YAML.load_file(File.join(__dir__, 'database.yml'))['test']
    
    # Set up logging
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::INFO
    
    begin
      puts "Connecting to MySQL database at #{config['host']}:#{config['port']}..."
      ActiveRecord::Base.establish_connection(config)
      
      # Test the connection
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "Successfully connected to MySQL database!"
    rescue => e
      puts "ERROR: Failed to connect to the MySQL database: #{e.message}"
      puts "Make sure the MySQL container is running: docker-compose up -d"
      puts "Check database credentials in: spec/support/database.yml"
      
      # Re-raise the error
      raise e
    end
  end

  def self.setup_database
    establish_connection
    
    # Create a User model for testing
    unless Object.const_defined?(:User)
      Object.const_set(:User, Class.new(ActiveRecord::Base) do
        self.table_name = 'users'
        
        def self.inspect
          "User(id, email, name)"
        end
      end)
    end
    
    # Verify that the users table exists and has data
    begin
      user_count = User.count
      puts "Found #{user_count} users in the database"
      
      if user_count == 0
        puts "WARNING: No users found in the database. Tests may fail."
      end
      
      # Display table structure for debugging
      puts "\nTable structure for users:"
      connection = ActiveRecord::Base.connection
      table_info = connection.exec_query("SHOW COLUMNS FROM users").to_a
      table_info.each do |column|
        puts "  #{column['Field']} (#{column['Type']})#{column['Key'] == 'PRI' ? ' PRIMARY KEY' : ''}#{column['Key'] == 'MUL' ? ' INDEXED' : ''}"
      end
      
      # Show indexes for debugging
      puts "\nIndexes on users table:"
      indexes = connection.exec_query("SHOW INDEXES FROM users").to_a
      indexes.each do |index|
        puts "  #{index['Key_name']} on #{index['Column_name']} (#{index['Index_type']})"
      end
      
      # Show actual EXPLAIN output for a query that should do a full table scan
      puts "\nEXPLAIN output for full table scan query:"
      full_scan_explain = connection.exec_query("EXPLAIN SELECT * FROM users WHERE name = 'User One'").to_a
      puts full_scan_explain.inspect
      
      # Show actual EXPLAIN output for a query that should use an index
      puts "\nEXPLAIN output for indexed query:"
      index_scan_explain = connection.exec_query("EXPLAIN SELECT * FROM users WHERE email = 'user1@example.com'").to_a
      puts index_scan_explain.inspect
    rescue => e
      puts "ERROR: Failed to query the users table: #{e.message}"
      puts "Make sure the database is properly initialized."
      raise e
    end
  end
end