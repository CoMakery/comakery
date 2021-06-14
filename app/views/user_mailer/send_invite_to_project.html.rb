class Views::UserMailer::SendInviteToProject < Views::Base
  use_instance_variables_for_assigns true

  needs :project, :project_role, :domain_name, :url
  def content
    row do
      text "You now have the role '#{project_role.capitalize}' for the project #{project.title} on #{domain_name}."
      link_to 'Go to project', url
    end
  end
end