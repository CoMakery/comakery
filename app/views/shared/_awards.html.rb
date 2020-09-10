class Views::Shared::Awards < Views::Base
  needs :project, :awards, :show_recipient, :current_account

  def content
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
          if project.token&._token_type?
            th(class: 'small-2 blockchain-address') { text 'Blockchain Transaction' }
          end
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
              text raw award.created_at.strftime('%b %d, %Y').gsub(' ', '&nbsp;')
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
                text raw ": #{markdown_to_html award.description}" if award.description.present?
                br
                span award.proof_id
              end
            end
            td(class: 'small-2') do
              if award.issuer
                img(src: account_image_url(award.issuer, 27), class: 'icon avatar-img', style: 'margin-right: 5px;')
              end
              text award.issuer_display_name
            end
            if project.token&._token_type?
              td(class: 'small-2 blockchain-address') do
                if award.ethereum_transaction_explorer_url
                  link_to award.ethereum_transaction_address_short, award.ethereum_transaction_explorer_url, target: '_blank'
                elsif award.recipient_address.blank? && current_account == award.account && show_recipient
                  link_to '(no account)', account_path
                elsif award.recipient_address.blank?
                  text '(no account)'
                elsif current_account&.decorate&.can_send_awards?(project)
                  link_to 'javascript:void(0)', class: 'metamask-transfer-btn transfer-tokens-btn', 'data-id': award.id, 'data-info': award.json_for_sending_awards do
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
    if project.token._token_type_on_ethereum?
      image_tag 'metamask2.png', alt: 'Metamask2'
    elsif project.token._token_type_qrc20?
      image_tag 'qrypto.png', alt: 'Qrypto'
    elsif project.token._token_type_qtum?
      image_tag 'ledger.png', alt: 'Ledger'
    elsif project.token._token_type_ada? || project.token._token_type_btc?
      image_tag 'trezor.png', alt: 'Trezor'
    elsif project.token._token_type_eos?
      image_tag 'eos.png', alt: 'Eos'
    elsif project.token._token_type_xtz?
      image_tag 'tezos.png', alt: 'Tezos'
    end
  end

  def display_status(award)
    if award.confirmed?
      i(class: 'fa fa-check-square')
    else
      show_recipient ? text('Emailed') : link_to('confirm', confirm_award_path(award.confirm_token))
    end
  end
end
