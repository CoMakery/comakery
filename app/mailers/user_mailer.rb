class UserMailer < ApplicationMailer
  def confirm_email account
    host =  ActionMailer::Base.asset_host
    @url = "#{host}/accounts/confirm/#{account.email_confirm_token}"
    mail to: account.email, subject: "Confirm your account email"
  end
end
