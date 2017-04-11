require 'chefspec'
require 'crack'
require 'rest-client'
require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

RSpec::Matchers.define :be_a do
  match do |actual|
    actual.is_a? Proc
  end

  def supports_block_expectations?
    true
  end
end
