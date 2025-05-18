# frozen_string_literal: true

require_relative 'lib/rspec_explain/version'

Gem::Specification.new do |spec|
  spec.name = "rspec-explain-matcher"
  spec.version = RspecExplain::VERSION
  spec.authors = ["Naofumi Fujii"]
  spec.email = [""]

  spec.summary = "RSpec custom matcher for ActiveRecord EXPLAIN"
  spec.description = "Provides a custom matcher to check if ActiveRecord queries are using indexes"
  spec.homepage = "https://github.com/naofumi-fujii/rspec-explain-matcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?("bin/", "test/", "spec/", "features/")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec", ">= 3.0"
  spec.add_dependency "activerecord", ">= 5.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
