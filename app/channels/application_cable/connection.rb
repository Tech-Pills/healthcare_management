module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      super
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if session_record = Session.find_by(id: cookies.signed[:session_id])
          ApplicationRecord.with_tenant(current_tenant) do
            self.current_user = session_record.user
          end
        end
      end
  end
end
