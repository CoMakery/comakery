class Views::Shared::Awards < Views::Base
  needs :project, :awards, :show_recipient, :current_account

  def content # rubocop:todo Metrics/PerceivedComplexity
    div(class: 'table-scroll table-box', style: 'margin-right: 0') do
      table(class: 'award-rows') do
        tr(class: 'header-row') do
          th(class: 'small-1') { text 'Type' }
          th(class: 'small-1') { text 'Amount' }
          th(class: 'small-1') { text 'Quantity' }
          th(class: 'small-1') { text 'Total Amount' }
          th(class: 'small-1') { text 'Date' }
          th(class: 'small-2') { text 'Recipient' } if show_recipient
          th(class: 'small-2') { text 'Contribution' }
          th(class: 'small-2') { text 'Authorized By' }
          th(class: 'small-2 blockchain-address') { text 'Blockchain Transaction' } if project.token&._token_type&.present?
          th(class: 'small-1', style: 'text-align: center') { text 'status' }
        end
        awards.each do |award|
          tr(class: 'award-row') do
            td(class: 'small-1 award-type') do
              text project.payment_description
            end

            td(class: 'small-1 award-unit-amount financial') do
              text award.amount_pretty
            end

            td(class: 'small-1 award-quantity financial') do
              text award.quantity
            end

            td(class: 'small-1 award-total-amount financial') do
              text award.total_amount_pretty
            end
            td(class: 'small-2') do
              text raw award.created_at.strftime('%b %d, %Y').gsub(' ', '&nbsp;') # rubocop:todo Rails/OutputSafety
            end
            if show_recipient
              td(class: 'small-2 recipient') do
                img(src: account_image_url(award.account, 27), class: 'icon avatar-img', style: 'margin-right: 5px;')
                text award.recipient_display_name
              end
            end
            td(class: 'small-2 description') do
              strong award.award_type.name.to_s
              span(class: 'help-text') do
                # rubocop:todo Rails/OutputSafety
                text raw ": #{markdown_to_html award.description}" if award.description.present?
                # rubocop:enable Rails/OutputSafety
                br
                span award.proof_id
              end
            end
            td(class: 'small-2') do
              img(src: account_image_url(award.issuer, 27), class: 'icon avatar-img', style: 'margin-right: 5px;') if award.issuer
              text award.issuer_display_name
            end
            if project.token&._token_type?
              td(class: 'small-2 blockchain-address') do
                if award.ethereum_transaction_explorer_url
                  link_to award.ethereum_transaction_address_short, award.ethereum_transaction_explorer_url, target: '_blank', rel: 'noopener'
                elsif award.recipient_address.blank? && current_account == award.account && show_recipient
                  link_to '(no account)', account_path
                elsif award.recipient_address.blank?
                  text '(no account)'
                elsif current_account&.decorate?(project)
                  link_to 'javascript:void(0)', class: 'metamask-transfer-btn transfer-tokens-btn', 'data-id': award.id do
                    span 'Send'
                    wallet_logo
                  end
                else
                  text '(pending)'
                end
              end
            end
            td(class: 'small-1', style: 'text-align: center') do
              display_status(award)
            end
          end
        end
      end
    end
  end

  def wallet_logo
    image_tag 'metamask2.png', alt: 'Metamask2'
  end

  def display_status(award)
    if award.confirmed?
      i(class: 'fa fa-check-square')
    else
      show_recipient ? text('Emailed') : link_to('confirm', confirm_award_path(award.confirm_token))
    end
  end
end
