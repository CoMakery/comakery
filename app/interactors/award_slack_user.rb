class AwardSlackUser
  include Interactor

  def call
    context.fail!(message: "missing slack_user_id") unless context.slack_user_id.present?

    authentication = Authentication.includes(:account).find_by(slack_user_id: context.slack_user_id)
    authentication ||= create_authentication(context)

    context.award = Award.new(context.award_params.merge(issuer: context.issuer, authentication_id: authentication.id))
    unless context.award.valid?
      context.fail!(message: context.award.errors.full_messages.join(", "))
    end
  end

  private

  def create_authentication(context)
    response = Comakery::Slack.new(context.issuer.slack_auth.slack_token).get_user_info(context.slack_user_id)
    account = Account.find_or_create_by(email: response.user.profile.email)
    unless account.valid?
      context.fail!(message: account.errors.full_messages.join(", "))
    end
    authentication = Authentication.create(account: account,
                                           provider: "slack",
                                           slack_team_name: context.project.slack_team_name,
                                           slack_team_id: context.project.slack_team_id,
                                           slack_team_image_34_url: context.project.slack_team_image_34_url,
                                           slack_team_image_132_url: context.project.slack_team_image_132_url,
                                           slack_user_name: response.user.name,
                                           slack_user_id: context.slack_user_id)

    unless authentication.valid?
      context.fail!(message: authentication.errors.full_messages.join(", "))
    end

    authentication
  end
end
