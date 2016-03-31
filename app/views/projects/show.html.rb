class Views::Projects::Show < Views::Base
  needs :project, :award, :awardable_authentications, :awardable_types, :award_data, :can_award

  PIE_CHART_CONTRIBUTORS = 12

  def make_charts
    text(<<-JAVASCRIPT.html_safe)
      $(function() {
        window.pieChart("#award-percentages", {"content": [#{award_data[:contributions][0...PIE_CHART_CONTRIBUTORS].map { |datum| pie_chart_data_element(datum) }.join(",")}]});
        window.stackedBarChart("#contributions-chart", #{award_data[:contributions_by_day].to_json});
      });
    JAVASCRIPT
  end

  def pie_chart_data_element(award_datum)
    {"label": award_datum[:name], "value": award_datum[:net_amount]}.to_json
  end

  def content
    if award_data[:contributions].present?
      content_for :js do
        make_charts
      end
    end

    content_for(:pre_body) {
      div(class: "project-head") {
        div(class: "small-12 medium-11 large-10 small-centered columns") {
          row(class: "project-title") {
            column("small-12") {
              h1 project.title
              p {
                text "by "
                strong project.slack_team_name
                if policy(project).edit?
                  a(class: "edit", href: edit_project_path(project)) {
                    i(class: "fa fa-pencil") {}
                    text " Edit Project"
                  }
                end
              }
            }
          }
          row {
            column("medium-5 small-12") {
              div(class: "project-image", style: "background-image: url(#{attachment_url(project, :image)})") {}
            }
            column("medium-7 small-12") {
              full_row {
                project.description_paragraphs.each { |paragraph| p paragraph }
              }
              row(class: "project-settings") {
                column("medium-5 small-12") {
                  text "Owner: "
                  b "#{project.owner_slack_user_name}"
                }
                column("medium-7 small-12") {
                  text "Visibility: "
                  b "#{project.public? ? "Public" : "Private"}"
                }
              }
              row(class: "project-tasks") {
                if project.tracker
                  column("medium-5 small-12") {
                    a(href: project.tracker, target: "_blank", class: "text-link") do
                      i(class: "fa fa-tasks")
                      text " Project Tasks"
                    end
                  }
                end
                if project.slack_team_domain
                  column("medium-7 small-12") {
                    a(href: "https://#{project.slack_team_domain}.slack.com", target: "_blank", class: "text-link") do
                      i(class: "fa fa-slack")
                      text " Project Slack Channel"
                    end
                  }
                end
              }
            }
          }
        }
      }
    }
    row(class: "project-body") {
      column("medium-5 small-12") {
        div(class:"award-send") {
          render partial: "award_send"
        }
      }
      column("medium-7 small-12 contributors-column") {
        row { column("small-12", class: "underlined-header") { text "Awards" } }

        row {
          column("small-12 medium-4", class: "centered coins-issued") {
            if award_data[:award_amounts][:my_project_coins]
              div(class: "centered coin-numbers") { text number_with_precision(award_data[:award_amounts][:my_project_coins], precision: 0, delimiter: ',') }
              div(class: "centered") { text "My Project Coins" }
            end
            div(class: "centered coin-numbers") {
              total_coins_issued = award_data[:award_amounts][:total_coins_issued]

              text number_with_precision(total_coins_issued, precision: 0, delimiter: ',')
              text "/"
              text number_with_precision(project.maximum_coins, precision: 0, delimiter: ',')

              percentage_issued = total_coins_issued.to_f / project.maximum_coins
              if percentage_issued >= 0.01
                text " (#{number_with_precision(percentage_issued, precision: 2)}%)"
              end
            }
            div(class: "centered") { text "Total Coins Issued" }

            p(class: "centered font-small") {
              a(href: project_awards_path(project), class: "text-link") {
                i(class: "fa fa-history")
                text " Award History"
              }
            }
          }
          column("medium-8 small-12", class: "centered") {
            div(id: "award-percentages")
          }
        }

        if award_data[:contributions].present?
          row { column("small-12", class: "underlined-header") { text "Recent Activity" } }

          full_row {
            div(id: "contributions-chart")
          }

          row {
            column("small-12") {
              award_data[:contributions].each do |contributor|
                div {
                  div(class: "float-right") { text number_with_precision(contributor[:net_amount], precision: 0, delimiter: ',') }
                  span contributor[:name]
                }
              end
            }
          }
        end
      }
    }
  end
end
