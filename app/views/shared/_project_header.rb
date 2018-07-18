class Views::Shared::ProjectHeader < Views::Projects::Base
  needs :project, :current_account

  def content
    content_for(:title) { project.title.strip }

    div(class: 'project-nav') {
      full_row {
        column('small-12') {
          h2 {
            text project.title
            if project.legal_project_owner.present?
              span(style: 'color: #9A9A9A;') {
                text " by #{project.legal_project_owner}"
              }
            end
          }
        }
      }
      full_row {
        ul(class: 'menu') {
          li(class: ('active' if controller_name == 'projects' && params[:action] != 'edit').to_s) {
            path = project.unlisted? ? unlisted_project_path(project.long_id) : project_path(project)
            a(href: path) {
              text 'Overview'
            }
          }

          li_if(project.can_be_access?(current_account), class: ('active' if controller_name == 'contributors').to_s) {
            a(href: project_contributors_path(project.show_id)) {
              text ' Contributors'
            }
          }

          li_if(project.can_be_access?(current_account), class: ('active' if controller_name == 'awards').to_s) {
            a(href: project_awards_path(project.show_id)) {
              text 'Awards'
            }
          }

          li_if(project.show_revenue_info?(current_account), class: ('active' if controller_name == 'revenues').to_s) {
            a(href: project_revenues_path(project.show_id)) {
              text 'Revenues'
            }
          }

          li_if(project.show_revenue_info?(current_account), class: ('active' if controller_name == 'payments').to_s) {
            a(href: project_payments_path(project.show_id)) {
              text 'Payments'
            }
          }
          # TODO: link to channel(s)
          # li_if(project.slack_team_domain) {
          #   a(href: "https://#{project.slack_team_domain}.slack.com/messages/#{project.slack_channel}", target: '_blank', class: 'text-link') {
          #     i(class: 'fa fa-slack')
          #     text 'Slack Channel'
          #   }
          # }

          li_if(project.tracker) {
            a(href: project.tracker, target: '_blank', class: 'text-link') {
              i(class: 'fa fa-tasks')
              text ' Project Tasks'
            }
          }

          li_if(project.ethereum_contract_explorer_url) {
            link_to 'Ξthereum Token', project.ethereum_contract_explorer_url,
              target: '_blank', class: 'text-link'
          }

          li_if(current_account && project.account == current_account, class: ('active' if controller_name == 'projects' && params[:action] == 'edit')) {
            a(class: 'edit', href: edit_project_path(project)) {
              i(class: 'fa fa-pencil') {}
              text 'Settings'
            }
          }
        }
      }
    }
  end
end
