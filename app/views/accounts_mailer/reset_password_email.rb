class Views::AccountsMailer::ResetPasswordEmail < Views::EmailBase
  needs :account
  needs :url

  def content
    full_row do
      td do
        h6 do
          text 'Hi '
          text(account.email)
          text ','
        end

        p do
          text "We received a request to change your #{Rails.application.config.project_name} password. To do this, please "
          link_to 'follow this link', url
          text '.'
        end

        p "If you didn't try to change your password, please disregard this email."
      end
    end
  end
end
