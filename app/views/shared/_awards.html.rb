class Views::Shared::Awards < Views::Base
  needs :project, :awards, :show_recipient, :current_account

  def content
    pages

    div(class: "table-scroll table-box") {
      table(class: "award-rows") {
        tr(class: "header-row") {
          th(class: "small-1") { text "Type" }
          th(class: "small-1") { text "Amount" }
          th(class: "small-1") { text "Quantity" }
          th(class: "small-1") { text "Total Amount" }
          th(class: "small-1") { text "Date" }
          if show_recipient
            th(class: "small-2") { text "Recipient" }
          end
          th(class: "small-2") { text "Contribution" }
          th(class: "small-2") { text "Authorized By" }
          if project.ethereum_enabled
            th(class: "small-2 blockchain-address") { text "Blockchain Transaction" }
          end
        }
        awards.sort_by(&:created_at).reverse.each do |award|
          tr(class: "award-row") {
            td(class: "small-1 award-type") {
              text number_with_delimiter(project.payment_description, :delimiter => ',')
            }

            td(class: "small-1 award-unit-amount financial") {
              text award.unit_amount
            }

            td(class: "small-1 award-quantity financial") {
              text award.quantity
            }

            td(class: "small-1 award-total-amount financial") {
              text award.total_amount_pretty
            }
            td(class: "small-2") {
              text raw award.created_at.strftime("%b %d, %Y").gsub(' ', '&nbsp;')
            }
            if show_recipient
              td(class: "small-2 recipient") {
                img(src: award.authentication.slack_icon, class: "icon avatar-img")
                text " " + award.recipient_display_name
              }
            end
            td(class: "small-2 description") {

              strong "#{award.award_type.name}"
              span(class: 'help-text') {

                text raw ": #{markdown_to_html award.description}" if award.description.present?
                br
                if award.proof_link
                  link_to award.proof_id, award.proof_link, target: '_blank'
                else
                  span award.proof_id
                end
              }
            }
            td(class: "small-2") {
              if award.issuer_slack_icon
                img(src: award.issuer_slack_icon, class: "icon avatar-img")
                text " "
              end
              text award.issuer_display_name
            }
            if project.ethereum_enabled
              td(class: "small-2 blockchain-address") {
                if award.ethereum_transaction_explorer_url
                  link_to award.ethereum_transaction_address_short, award.ethereum_transaction_explorer_url, target: '_blank'
                elsif award.recipient_address.blank? && current_account == award.recipient_account && show_recipient
                  link_to '(no account)', account_path
                elsif award.recipient_address.blank?
                  text '(no account)'
                else
                  text '(pending)'
                end
              }
            end
          }
        end
      }
    }

    pages
  end

  def pages
    full_row {
      div(class: 'callout clearfix') {
        div(class: 'pagination float-right') {
          text paginate project.awards.page(params[:page])
        }
      }
    }
  end
end
