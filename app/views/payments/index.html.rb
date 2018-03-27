class Views::Payments::Index < Views::Projects::Base
  needs :project, :payment, :current_account_deco

  def content
    render partial: 'shared/project_header'
    column {
      if current_account_deco.present?
        full_row {
          column('small-12 content-box') {
            if current_account_deco.same_team_project?(project) && current_user_has_awards?
              form_for [project, payment], html: { class: 'conversational-form' } do |f|
                row {
                  text 'Redeem '
                  f.number_field(:quantity_redeemed, class: 'input-group-field')
                  span(class: 'my-shares') do
                    text "of my #{current_account_deco.total_awards_remaining_pretty(project)} revenue shares"
                  end
                }

                row {
                  text 'For '
                  span(class: 'revenue-per-share') { text project.revenue_per_share_pretty }
                  text ' each'
                }

                row {
                  inline_errors(payment, :total_value)
                  inline_errors(payment, :quantity_redeemed)
                }

                row {
                  f.submit('Redeem My Revenue Shares', class: buttonish(:expand))
                }
              end
              row(class: 'conversational-form') {
                span(class: 'help-text min-transaction-amount') { text "The minimum transaction amount is #{project.minimum_payment}" }
              }
            else
              row(class: 'conversational-form no-awards-message') {
                p {
                  text 'Earn '
                  link_to 'awards', project_path(project, anchor: 'awards')
                  text ' by contributing to the project - then cash them out here for your share of the revenue.'
                }
              }
            end
          }
        }

        full_row {
          render partial: 'shared/table/my_balance'
          render partial: 'shared/table/current_share_value'
        }
      end
      br
      full_row {
        if project.payment_history.any?
          h3 'Payments'

          div(class: 'table-scroll table-box payments') {
            table(class: 'table-scroll', style: 'width: 100%') {
              tr(class: 'header-row') {
                th { text 'Date' }
                th { text 'Payee' }
                th { text 'Share Value' }
                th { text 'Quantity' }
                th { text 'Total Value' }
                th { text 'Transaction Fee' }

                th { text 'Transaction Reference' }
                th { text 'Total Payment' }
                th { text 'Issuer' }
                th { text 'Status' }
              }

              project.payment_history.decorate.each do |payment|
                tr(class: 'award-row') {
                  payment_td('created-at') { text payment.created_at }

                  payment_td('payee') {
                    if payment.payee_avatar
                      img(src: payment.payee_avatar, class: 'icon avatar-img')
                      text ' '
                    end

                    text payment.payee_name
                  }
                  payment_td('share-value') { text payment.share_value_pretty }
                  payment_td('quantity-redeemed') { text payment.quantity_redeemed }

                  payment_td('total-value') { text payment.total_value_pretty }

                  if !payment.reconciled? && current_user && project.account==current_user
                    form_for([project, payment]) do |f|
                      payment_td('transaction-fee') { f.text_field :transaction_fee, value: payment.transaction_fee }

                      payment_td('transaction-reference') do
                        f.text_field :transaction_reference, value: payment.transaction_reference
                      end

                      payment_td('total-payment') { f.submit 'Reconcile', class: 'button' }
                    end
                  else
                    payment_td('transaction-fee') { text payment.transaction_fee_pretty }
                    payment_td('transaction-reference') { text payment.transaction_reference }
                    payment_td('total-payment') { text payment.total_payment_pretty }
                  end

                  payment_td('issuer') {
                    if payment.issuer_avatar
                      img(src: payment.issuer_avatar, class: 'icon avatar-img')
                      text ' '
                    end

                    text payment.issuer_name
                  }
                  payment_td('status') { text payment.status }
                }
              end
            }
          }
        else
          div(class: 'payments') { text 'No payments yet.' }
        end
      }
    }
  end

  def payment_td(column_matcher)
    td {
      span(class: "margin-small margin-collapse inline-block #{column_matcher}") { yield }
    }
  end

  def conversational
    span(class: 'conversational-form') { yield }
  end

  def current_user_has_awards?
    current_account_deco.account.total_awards_remaining(project) > 0
  end
end
