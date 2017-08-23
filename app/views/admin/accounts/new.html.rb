class Views::Admin::Accounts::New < Views::Base
  def content
    full_row do
      h1('New account')

      render 'form'

      link_to 'Back', admin_accounts_path
    end
  end
end
