class Views::Contributors::Index < Views::Projects::Base
  needs :project, :award_data, :contributors

  def content
    render partial: 'shared/project_header'
    column {
      full_row {
        if award_data[:contributions_summary_pie_chart].present?
          column('large-4 medium-12 summary float-left') {
            h3 "Lifetime #{project.payment_description} Awarded To Contributors"

              p {
                div(id: 'award-percentages', class: 'royalty-pie') {}
              }
              content_for :js do
                make_charts
              end
          }
        end

        render partial: 'shared/table/unpaid_revenue_shares'
        render partial: 'shared/table/unpaid_pool'
      }

      pages
      full_row {
        if contributors.present?
          div(class: 'table-scroll table-box contributors') {
            table(class: 'table-scroll', style: 'width: 100%') {
              tr(class: 'header-row') {
                th 'Contributors'
                th { text "Lifetime #{project.payment_description} Awarded" }
                th { text "Unpaid #{project.payment_description}" } if project.revenue_share?
                th { text 'Unpaid Revenue Share Balance' } if project.revenue_share?
                th { text 'Lifetime Paid' } if project.revenue_share?
              }
              contributors.decorate.each do |contributor|
                tr(class: 'award-row') {
                  td(class: 'contributor') {
                    img(src: account_image_url(contributor, 27), class: 'icon avatar-img')
                    div(class: 'margin-small margin-collapse inline-block') {
                      text contributor.name
                      table(class: 'table-scroll table-box overlay') {
                        tr {
                          th(style: 'padding-bottom: 20px') {
                            text 'Contribution Summary'
                          }
                        }
                        contributor.award_by_project(project).each do |award|
                          tr {
                            td { text award[:name] }
                            td { text number_with_delimiter(award[:total], seperator: ',') }
                          }
                        end
                      }
                    }
                  }
                  td(class: 'awards-earned financial') {
                    span(class: 'margin-small') {
                      text contributor.total_awards_earned_pretty(project)
                    }
                  }
                  if project.revenue_share?
                    td(class: 'award-holdings financial') {
                      span(class: 'margin-small') {
                        text text contributor.total_awards_remaining_pretty(project)
                      }
                    }

                    td(class: 'holdings-value financial') {
                      span(class: 'margin-small') {
                        text contributor.total_revenue_unpaid_remaining_pretty(project)
                      }
                    }

                    td(class: 'paid hidden financial') {
                      span(class: 'margin-small') {
                        text contributor.total_revenue_paid_pretty(project)
                      }
                    }
                  end
                }
              end
            }
          }
        end
      }
      pages
    }
  end

  def make_charts
    text(<<-JAVASCRIPT.html_safe)
      $(function() {
        window.pieChart("#award-percentages", {"content": #{pie_chart_data}});
      });
    JAVASCRIPT
  end

  def pie_chart_data
    award_data[:contributions_summary_pie_chart].map do |award|
      { label: award[:name], value: award[:net_amount] }
    end.to_json
  end

  def pages
    full_row {
      div(class: 'callout clearfix') {
        div(class: 'pagination float-right') {
          text paginate contributors
        }
      }
    }
  end
end
