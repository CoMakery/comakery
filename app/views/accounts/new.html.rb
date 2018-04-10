class Views::Accounts::New < Views::Base
  needs :account

  def content
    row {
      column(%i[small-12 large-6], class: 'large-centered') {
        h1('Signup')

        form_for account do |f|
          row {
            column('large-12') {
              with_errors(account, :email) {
                label {
                  text 'E-mail: '
                  f.text_field :email
                }
              }
            }

            column('large-12') {
              with_errors(account, :first_name) {
                label {
                  text 'First Name: '
                  f.text_field :first_name
                }
              }
            }

            column('large-12') {
              with_errors(account, :last_name) {
                label {
                  text 'Last Name: '
                  f.text_field :last_name
                }
              }
            }

            column('large-12') {
              with_errors(account, :nickname) {
                label {
                  text 'Nickname: '
                  f.text_field :nickname
                }
              }
            }

            column('large-12') {
              with_errors(account, :password) {
                label {
                  text 'Password: '
                  f.password_field :password
                }
              }
            }

            column('large-12') {
              f.submit class: buttonish(:medium)
            }
          }
        end
      }
    }
  end
end
