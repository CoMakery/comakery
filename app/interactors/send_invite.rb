class SendInvite
  include Interactor

  delegate :params, :whitelabel_mission, :project, to: :context

  def call
    account = GetAccount.call(whitelabel_mission: whitelabel_mission, email: params[:email]).account

    if account.blank?
      if email_valid?
        project_invite = project.invites.find_by(email: params[:email])

        if project_invite.present?
          if project_invite.expired?
            project_invite.update_expires_at

            send_invite_to_platform(params[:email], project_invite.token, project, params[:role])
          else
            context.fail!(["Project invite is already sent to #{params[:email]}"])
          end
        else
          project_invite = project.invites.new(email: params[:email], role: params[:role])

          if project_invite.save
            send_invite_to_platform(params[:email], project_invite.token, project, params[:role])
          else
            context.fail!(errors: project_invite.errors.full_messages)
          end
        end
      else
        # TODO: Clarify error message
        context.fail!(errors: ['Email is invalid'])
      end
    else
      project_role = project.project_roles.find_by(account: account)

      if project_role.present?
        context.fail!(errors: ["User already has #{project_role.role} permissions for this project. " \
                               'You can update their role with the action menu on this Accounts page'])
      else
        project_role = project.project_roles.new(account: account, role: params[:role])

        if project_role.save
          UserMailer.send_invite_to_project(
            account.email,
            project,
            params[:role],
            domain_name
          ).deliver_now
        else
          context.fail!(errors: project_role.errors.full_messages)
        end
      end
    end
  end

  private

    def email_valid?
      params[:email] =~ URI::MailTo::EMAIL_REGEXP
    end

    def send_invite_to_platform(email, token, project, role)
      UserMailer.send_invite_to_platform(email, token, project, role, domain_name).deliver_now
    end

    def domain_name
      if whitelabel_mission
        whitelabel_mission.whitelabel_domain
      else
        ENV['APP_HOST']
      end
    end
end
