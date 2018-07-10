class Views::Projects::AwardSend < Views::Base
  needs :project, :award, :awardable_types, :can_award

  def content
    div(id: 'award-send') {
      row(class: 'awarded-info-header') {
        if can_award
          h3 "Award #{project.payment_description}"
        else
          h3 "Earn #{project.payment_description}"
        end
      }
      br
      form_for [project, award] do |f|
        div(class: 'award-types') {
          if can_award
            row {
              column('small-12') {
                label {
                  text 'Communication Channel'
                  options = []
                  if project.channels.any?
                    options = capture do
                      options_from_collection_for_select([Channel.new(name: 'Email')] + project.channels, :id, :name_with_provider, award.channel_id)
                    end
                  end
                  f.select :channel_id, options, {}, class: 'fetch-channel-users'
                }
              }
            }

            row(class: 'award-uid') {
              column('small-12') {
                if award.channel && award.channel.members(current_account).any?
                  label(class: 'uid-select') {
                    options = capture do
                      options_for_select(award.channel.members(current_account), award.uid)
                    end
                    text 'User'
                    f.select :uid, options, include_blank: true, class: 'member-select'
                  }

                  label(class: 'uid-email hide') {
                    text 'Email Address'
                    f.text_field :uid, class: 'award-email', value: award.email, name: nil
                  }
                else
                  label(class: 'uid-select hide') {
                    text 'User'
                    f.select :uid, []
                  }

                  label(class: 'uid-email') {
                    text 'Email Address'
                    f.text_field :uid, class: 'award-email', value: award.email
                  }
                end
              }
            }

            row {
              column('small-12') {
                label {
                  text 'Award Type'
                  options = []
                  if awardable_types.any?
                    options = capture do
                      options_from_collection_for_select(awardable_types.order('amount asc').decorate, :id, :name_with_amount, award.award_type_id)
                    end
                  end
                  f.select :award_type_id, options, {}
                }
              }
            }

            row {
              column('small-3') {
                label {
                  text 'Quantity'
                  f.text_field(:quantity, type: :text, default: 1, class: 'financial')
                }
              }

              row {
                column('small-12') {
                  with_errors(project, :description) {
                    label {
                      text 'Description'
                      f.text_area(:description)
                      link_to('Styling with Markdown is Supported', 'https://guides.github.com/features/mastering-markdown/', class: 'help-text')
                    }
                  }
                }
              }
              row {
                column('small-12') {
                  f.submit('Send Award', class: buttonish)
                }
              }
            }
          else
            project.award_types.order('amount asc').decorate.each do |award_type|
              row(class: 'award-type-row') {
                if award_type.active?
                  column('small-12') {
                    with_errors(project, :account_id) {
                      label {
                        row {
                          column('small-12') {
                            row {
                              span(award_type.name)
                              span(class: ' financial') {
                                text " (#{award_type.amount_pretty})"
                              }
                              text ' (Community Awardable)' if award_type.community_awardable?
                              br
                              span(class: 'help-text') { text raw(award_type.description_markdown) }
                            }
                          }
                        }
                      }
                    }
                  }
                end
              }
            end
          end
        }
      end
    }
  end
end
