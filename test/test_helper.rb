ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "active_record/tenanted/testing"
require_relative "test_helpers/session_test_helper"

ApplicationRecord.current_tenant = 'test-medical-center'  
PatientsRecord.current_tenant = 'test-medical-center'

module ActiveSupport
  class TestCase
    include SessionTestHelper
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    fixtures :all

    def before_setup
      # Use gem's tenant_genesis pattern but for both tenant classes
      tenant_genesis(ApplicationRecord)
      tenant_genesis(PatientsRecord)
      
      ensure_global_fixtures
      super
    end

    private

    def tenant_genesis(klass)
      begin
        klass.destroy_tenant('test-medical-center') 
      rescue ActiveRecord::Tenanted::TenantDoesNotExistError
        Rails.logger.info "#{klass} tenant does not exist yet: test-medical-center"
      end
      klass.create_tenant('test-medical-center')
    end

    def ensure_global_fixtures
      User.create!(id: 1, email_address: "one@example.com", password: "password") unless User.exists?(1)
      User.create!(id: 2, email_address: "two@example.com", password: "password") unless User.exists?(2)
      
      Practice.create!(id: 1, name: "Test Medical Center", address: "123 Main Street", phone: "555-0001", email: "contact@testmedical.com", license_number: "LIC001", slug: "test-medical-center", active: true) unless Practice.exists?(1)
      Practice.create!(id: 2, name: "Family Health Clinic", address: "456 Oak Avenue", phone: "555-0002", email: "info@familyhealth.com", license_number: "LIC002", slug: "family-health-clinic", active: true) unless Practice.exists?(2)
    end

    def load_tenant_fixtures(fixture_names = [])
      return if fixture_names.empty?
      
      app_record_fixtures = fixture_names.select { |name| ['staffs', 'appointments'].include?(name) }
      if app_record_fixtures.any?
        ApplicationRecord.with_tenant('test-medical-center') do
          ActiveRecord::FixtureSet.create_fixtures('test/fixtures', app_record_fixtures)
        end
      end
      
      patients_fixtures = fixture_names.select { |name| ['patients'].include?(name) }
      if patients_fixtures.any?
        PatientsRecord.with_tenant('test-medical-center') do
          ActiveRecord::FixtureSet.create_fixtures('test/fixtures', patients_fixtures)
        end
      end
    end
  end
end
