module Views
  module PasswordResets
    class New < Base
      def content
        row do
          column('medium-6', class: 'medium-centered') do
            h2('Forgot your password?')
            form_tag password_resets_path, method: :post do
              label do
                text 'Email '
                text_field_tag :email
              end
              submit_tag 'Reset my password!', class: buttonish(:small, :expand)
            end
          end
        end
      end
    end
  end
end
