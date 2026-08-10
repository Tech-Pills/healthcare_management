# Ensure activerecord-tenanted compatibility with rails-erd
# Override the default erd task to set a tenant before running

# Clear the default erd task if it exists
Rake::Task["erd"].clear if Rake::Task.task_defined?("erd")

# Redefine the erd task with tenant support
desc "Generate an Entity-Relationship Diagram based on your models (tenant-aware)"
task erd: :environment do
  # Set tenant before anything else
  if defined?(ApplicationRecord) && ApplicationRecord.respond_to?(:current_tenant=)
    tenant = ApplicationRecord.tenants.first rescue nil

    if tenant.nil?
      puts "Error: No tenants available for ERD generation."
      puts "Please create a practice first."
      exit 1
    end

    puts "Setting tenant for ERD generation: #{tenant}"
    ApplicationRecord.current_tenant = tenant
  end

  # Now run the erd:generate task
  Rake::Task["erd:generate"].invoke
end
