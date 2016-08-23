class Views::Shared::Awards < Views::Base
  needs :awards, :show_recipient

  def content
    div(class: "award-rows") {
      row(class: "header-row") {
        column("small-1") { div(class: "header") { text "Tokens Issued" } }
        column("small-2") { div(class: "header") { text "Date" } }
        column("small-2") { div(class: "header") { text "Recipient" } } if show_recipient
        column("small-3") { div(class: "header") { text "Contribution" } }
        column("small-2") { div(class: "header") { text "Authorized By" } }
        column("small-2") { div(class: "header") { text "Blockchain Transaction" } }
      }
      awards.sort_by(&:created_at).reverse.each do |award|
        row(class: "award-row") {
          column("small-1") {
            text number_with_delimiter(award.award_type.amount, :delimiter => ',')
          }
          column("small-2") {
            text raw award.created_at.strftime("%b %d, %Y").gsub(' ', '&nbsp;')
          }
          if show_recipient
            column("small-2") {
              img(src: award.authentication.slack_icon, class: "icon avatar-img")
              text " " + award.recipient_display_name
            }
          end
          column("small-3") {
            if award.proof_link
              link_to award.proof_id_short, award.proof_link, target: '_blank'
            else
              span award.proof_id_short
            end
            br
            strong "#{award.award_type.name}"
            text raw ": #{markdown_to_html award.description}" if award.description.present?
          }
          column("small-2") {
            img(src: award.issuer.team_auth(award.award_type.project.slack_team_id).slack_icon, class: "icon avatar-img")
            text " " + award.issuer_display_name
          }
          column("small-2") {
            if award.ethereum_transaction_explorer_url
              link_to award.ethereum_transaction_address_short, ethereum_transaction_explorer_url, target: '_blank'
            else
              text '(pending)'
            end
          }
          column("small-2") {} unless show_recipient
        }
      end
    }
  end
end
