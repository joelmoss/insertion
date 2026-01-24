# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'
require 'rails/test_help'
require 'minitest/difftastic'
require 'maxitest/autorun'

module ActiveSupport
  class TestCase
    parallelize workers: :number_of_processors
  end
end
