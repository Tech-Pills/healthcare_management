ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    include SessionTestHelper

    fixtures :all

    def after_teardown
      super
      FileUtils.rm_rf(ActiveStorage::Blob.service.root) if ActiveStorage::Blob.service.respond_to?(:root)
    end
  end
end

Minitest.after_run do
  FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
end

class ActionDispatch::IntegrationTest
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root) if ActiveStorage::Blob.service.respond_to?(:root)
  end
end
