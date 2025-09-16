class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private


  def current_user
    Current.session&.user
  end

  def current_practice
    @current_practice ||= current_user&.staff&.practice
  end
  helper_method :current_practice
end
