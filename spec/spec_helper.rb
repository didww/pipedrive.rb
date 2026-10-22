# frozen_string_literal: true

require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(SimpleCov::Formatter::HTMLFormatter)
SimpleCov.start do
  add_filter 'spec'
  # A partial run covers only part of the library, so the threshold would fail it. `rake` passes a
  # --pattern argument that matches /_spec\.rb/, so the file list cannot be used to detect one: run
  # a subset with PARTIAL=true to skip the check.
  minimum_coverage(76) unless ENV['PARTIAL'] == 'true'
end
require 'webmock'
require 'webmock/rspec'
require 'pipedrive'

RSpec.configure do |config|
end
