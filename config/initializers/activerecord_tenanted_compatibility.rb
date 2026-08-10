# Compatibility patch for activerecord-tenanted with Rails 8.1
# Adds missing methods to UntenantedConnectionPool for compatibility with rails-erd
# and other tools that expect standard ActiveRecord connection pool interface

module ActiveRecord
  module Tenanted
    class UntenantedConnectionPool
      # Rails 8.1 connection pools have a permanent_lease? method
      # that rails-erd and other tools may call.
      # We return true to indicate that connections should use lease_connection
      # instead of active_connection, which will raise a proper error if
      # someone tries to connect without a tenant.
      def permanent_lease?
        true
      end

      # Rails connection pools have an active_connection method
      # to retrieve the currently active connection for the current thread.
      # Since UntenantedConnectionPool doesn't support actual connections,
      # we return nil to indicate no active connection is available.
      def active_connection
        nil
      end
    end
  end
end
