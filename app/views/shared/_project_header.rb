class Views::Shared::ProjectHeader < Views::Projects::Base
  needs :project

  def content
    content_for(:title) { project.title.strip }
    content_for(:description) { project.description_text(150) }

    div(class: "project-nav") {
      full_row {
        column("small-12") {
          h2 project.title
        }
      }
      full_row {
        ul(class: "menu") {
          li {
            a(href: project_path(project)) {
              text "Overview"
            }
          }

          li {
            a(href: project_contributors_path(project)) {
              text " Contributors"
            }
          }

          li {
            a(href: project_licenses_path(project)) {
              i(class: "fa fa-gavel")
              text "Contribution License"
            }
          }

          li {
            a(href: project_awards_path(project)) {
              i(class: "fa fa-history")
              text "History"
            }
          }


          li_if(policy(project).edit?) {
            a(class: "edit", href: edit_project_path(project)) {
              i(class: "fa fa-pencil") {}
              text "Edit Project"
            }
          }

          li_if(project.slack_team_domain) {
            a(href: "https://#{project.slack_team_domain}.slack.com/messages/#{project.slack_channel}", target: "_blank", class: "text-link") {
              i(class: "fa fa-slack")
              text "Slack Channel"
            }
          }

          li_if(project.tracker) {
            a(href: project.tracker, target: "_blank", class: "text-link") {
              i(class: "fa fa-tasks")
              text " Project Tasks"
            }
          }

          li_if(project.ethereum_contract_explorer_url) {
            link_to "Ξthereum Smart Contract", project.ethereum_contract_explorer_url,
                    target: "_blank", class: "text-link"
          }
        }
      }
    }
  end
end