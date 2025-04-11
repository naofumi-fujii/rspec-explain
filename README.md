# RSpec Explain

A Ruby gem providing a custom RSpec matcher to detect when ActiveRecord queries would perform full table scans rather than using indexes.

## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'rspec-explain'
end
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install rspec-explain
```

## Usage

In your RSpec tests, you can now use the `raise_full_scan_error` matcher to verify that your ActiveRecord queries would not perform full table scans:

```ruby
require 'rspec_explain'

RSpec.describe User, type: :model do
  it 'raises an error when the query would perform a full table scan' do
    # Assuming the User table has name, age, and hobby columns without indexes
    expect(User.where(name: 'naofumi-fujii', age: 37, hobby: 'テニス')).to raise_full_scan_error
  end
  
  it 'does not raise an error when the query uses indexes' do
    # Assuming the User table has an index on the email column
    expect(User.where(email: 'example@example.com')).not_to raise_full_scan_error
  end
end
```

## How it works

The gem uses ActiveRecord's `explain` method to analyze the query execution plan. It then checks if the plan indicates a full table scan (rather than using an index), which is database-specific:

- PostgreSQL: Looks for 'Seq Scan' vs 'Index Scan'
- MySQL: Looks for 'type: ALL' vs more efficient types like 'ref', 'range', etc.
- SQLite: Looks for 'SCAN TABLE' vs 'SEARCH TABLE'

If a full table scan is detected, the matcher raises `RspecExplain::FullScanError`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/naofumi-fujii/rspec-explain.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
