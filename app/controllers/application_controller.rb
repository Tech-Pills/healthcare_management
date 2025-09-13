class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_tenant

  private

  def set_current_tenant
    return unless current_user&.staff?

    practice = current_user.staff.practice
    if practice
      ApplicationRecord.current_tenant = practice.slug
    end
  rescue ActiveRecord::Tenanted::NoTenantError
    redirect_to logout_path, alert: "Please create a practice to get started."
  end

  def current_user
    Current.session&.user
  end

  def current_practice
    @current_practice ||= current_user&.staff&.practice
  end
  helper_method :current_practice
end
