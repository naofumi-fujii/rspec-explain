# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'
require_relative "rspec_explain/version"
require_relative "rspec_explain/errors"
require_relative "rspec_explain/matchers"

module RspecExplain
  extend T::Sig
end
