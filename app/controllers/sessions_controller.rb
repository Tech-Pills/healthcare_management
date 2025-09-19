class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    practice = Practice.find_by(slug: ApplicationRecord.current_tenant)
    unless practice
      redirect_to new_session_path, alert: "Invalid practice domain."
      return
    end

    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
