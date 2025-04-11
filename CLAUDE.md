# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake spec

# Run a single test (replace LINE_NUMBER)
bundle exec rspec spec/rspec_explain_spec.rb:LINE_NUMBER

# Run tests with MySQL (recommended)
./bin/test-mysql

# Lint check using standard Ruby style
bundle exec rubocop
```

## Code Style Guidelines

1. **Formatting**: Use 2-space indentation, single quotes for strings unless interpolation is needed. Add `# frozen_string_literal: true` to all Ruby files.

2. **Naming**: Follow Ruby conventions - CamelCase for classes/modules, snake_case for methods/variables.

3. **Error handling**: Define custom errors in `lib/rspec_explain/errors.rb` and use proper error classes.

4. **Testing**: Write tests for all new functionality. Ensure database tests use the Docker MySQL setup.

5. **Documentation**: Add Yard-style comments to public APIs and update README for significant changes.

6. **Dependencies**: Requires Ruby >= 2.6.0. Primary dependencies are RSpec and ActiveRecord.

## Project Structure
- `lib/rspec_explain/matchers.rb`: Core functionality with the RSpec matcher
- `spec/`: Test suite
- `docker/`: MySQL Docker setup for database tests

Always run the test suite before committing changes.