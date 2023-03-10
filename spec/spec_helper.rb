# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "collectionspace/refcache"
require "pry"
require_relative "./helpers"

RSpec.configure do |config|
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
