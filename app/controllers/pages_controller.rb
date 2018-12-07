class PagesController < ApplicationController
  skip_before_action :require_login, except: %i[featured home]
  skip_before_action :require_email_confirmation, only: %i[featured home landing add_interest]
  skip_after_action :verify_authorized

  def landing
    if current_account
      if current_account.finished_contributor_form?
        redirect_to action: :featured
      else
        @paperform_id = (ENV['APP_NAME'] == 'demo' ? 'demo-homepage' : 'homepage')
        render :home
      end
    end
  end

  def home; end

  def featured
    unless current_account.finished_contributor_form?
      current_account.update(contributor_form: true)
    end
    unless current_account.confirmed?
      flash[:alert] = 'Please confirm your email before continuing.'
    end
  end

  def add_interest
    @interest = current_user.interests.new
    @interest.project = params[:project]
    @interest.protocol = params[:protocol]
    @interest.save
    respond_to do |format|
      format.json { render json: @interest.to_json }
    end
  end
end
