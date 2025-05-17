# RSpec Explain

A Ruby gem providing custom RSpec matchers to detect performance issues in ActiveRecord queries by analyzing EXPLAIN results.

## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'rspec-explain-matcher'
end
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install rspec-explain-matcher
```

## Usage

### Full Table Scan Matchers

The library provides two equivalent matchers to check if a query performs a full table scan:

#### 1. Original Matcher

```ruby
require 'rspec_explain'

RSpec.describe User, type: :model do
  it 'raises an error when the query would perform a full table scan' do
    # Assuming the User table has name column without an index
    expect(User.where(name: 'naofumi-fujii')).to raise_full_scan_error
  end
  
  it 'does not raise an error when the query uses indexes' do
    # Assuming the User table has an index on the email column
    expect(User.where(email: 'example@example.com')).not_to raise_full_scan_error
  end
end
```

#### 2. Alternative Matcher (Same Functionality)

```ruby
RSpec.describe User, type: :model do
  it 'detects when the query would perform a full table scan' do
    # Assuming the User table has name column without an index
    expect(User.where(name: 'naofumi-fujii')).to detect_full_table_scan
  end
  
  it 'does not detect full table scan when the query uses indexes' do
    # Assuming the User table has an index on the email column
    expect(User.where(email: 'example@example.com')).not_to detect_full_table_scan
  end
end
```

Both matchers have identical functionality - choose the one that reads better in your tests.

### New Matchers

The library now includes several additional matchers to check different aspects of query performance:

#### Access Type Matcher

Checks if a query uses an efficient access type (not 'ALL' or 'index'):

```ruby
expect(User.where(email: 'example@example.com')).to have_good_access_type
```

#### Row Count Matcher

Checks if a query scans fewer than a specified number of rows:

```ruby
expect(User.where(email: 'example@example.com')).to scan_fewer_than(1000)
```

#### Expensive Operation Matcher

Checks if a query avoids expensive operations like filesort or temporary tables:

```ruby
expect(User.where(email: 'example@example.com')).to avoid_expensive_operations
```

#### Index Usage Matcher

Checks if a query uses an index:

```ruby
expect(User.where(email: 'example@example.com')).to use_index
```

#### Available Index Matcher

Checks if a query uses available index candidates:

```ruby
expect(User.where(email: 'example@example.com')).to use_available_indexes
```

### Combining Matchers

You can use multiple matchers to thoroughly check your queries:

```ruby
describe "User.find_active" do
  let(:query) { User.where(status: 'active') }
  
  it "is optimized for performance" do
    # Check if it uses a good access type
    expect(query).to have_good_access_type
    
    # Check if it scans few enough rows
    expect(query).to scan_fewer_than(1000)
    
    # Check if it avoids expensive operations
    expect(query).to avoid_expensive_operations
    
    # Check if it uses an index
    expect(query).to use_index
  end
end
```

## How it works

The gem uses ActiveRecord's `explain` method to analyze the query execution plan and checks for various performance issues:

| Item         | Issues to check                         | Matcher to use                |
|--------------|----------------------------------------|------------------------------|
| `type`       | 'ALL', 'index' (inefficient access)    | `have_good_access_type`     |
| `rows`       | Too many rows scanned                  | `scan_fewer_than(threshold)` |
| `Extra`      | 'Using filesort', 'Using temporary'    | `avoid_expensive_operations` |
| `key`        | NULL (no index used)                  | `use_index`                  |
| `possible_keys` | Available indexes not being used     | `use_available_indexes`      |

Database-specific detection is implemented for:
- MySQL (primary focus)
- PostgreSQL (basic support)
- SQLite (basic support)

## Testing with Docker MySQL

This gem uses real MySQL for testing through Docker:

```bash
# Start the container and run tests
./bin/test-mysql

# Or manually
docker-compose up -d
bundle exec rspec
docker-compose down
```

## Development

The project includes a Docker setup that makes it easy to develop and test the gem with a real MySQL database. The docker-compose.yml file defines a MySQL 8.0 service that will be initialized with a sample schema and data for testing.

### Type Checking

This project uses [Sorbet](https://sorbet.org/) for static type checking. All Ruby files include type signatures and are set to `# typed: strict`.

To run the type checker:

```bash
bundle exec rake typecheck
```

For development, you can regenerate the RBI files with:

```bash
bundle exec tapioca dsl
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/naofumi-fujii/rspec-explain-matcher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
