class ProjectPolicy < ApplicationPolicy
  attr_reader :account, :project

  def initialize(account, project)
    @account = account
    @project = project
  end

  class Scope < Scope
    attr_reader :account, :scope

    def initialize(account, scope)
      @account = account
      @scope = scope
    end

    def resolve
      if @account
        account.accessable_projects(scope)
      elsif scope.first&.whitelabel?
        scope.non_confidential.publics
      else
        scope.publics
      end
    end
  end

  def show?
    project.public_listed? || (team_member? && !project.archived?) || edit?
  end

  def unlisted?
    project.public_unlisted? || (team_member? && !project.archived?) || edit?
  end

  def edit?
    account.present? && (project_owner? || project_admin?)
  end

  def show_contributions_to_everyone?
    project.public? && !project.require_confidentiality?
  end

  def show_contributions_to_team?
    team_member? && !project.archived? && !project.require_confidentiality?
  end

  def show_contributions?
    show_contributions_to_everyone? || show_contributions_to_team? || edit? || project_observer?
  end

  def show_award_types?
    show? || unlisted?
  end

  def show_whitelabel_award_types?
    show_award_types? && project.mission.project_awards_visible?
  end

  def show_transfer_rules?
    show_contributions? && project.supports_transfer_rules?
  end

  alias update? edit?
  alias send_award? edit?
  alias accesses? edit?
  alias regenerate_api_key? edit?
  alias add_admin? edit?
  alias remove_admin? edit?
  alias create_transfer? edit?
  alias update_transfer? edit?
  alias edit_accounts? edit?
  alias edit_reg_groups? edit?
  alias edit_transfer_rules? edit?
  alias freeze_token? edit?
  alias transfer_types? edit?
  alias edit_hot_wallet_mode? edit?
  alias add_person? edit?
  alias change_permissions? edit?
  alias accounts? show_contributions?
  alias transfers? show_contributions?

  def export_transfers?
    edit? || project_observer?
  end

  def project_owner?
    account.present? && (project.account == account)
  end

  def project_admin?
    account.present? && (project.project_admins.include? account)
  end

  def project_interested?
    account.present? && (project.project_interested.include? account)
  end

  def project_observer?
    account.present? && (project.project_observers.include? account)
  end

  def refresh_transfer_rules?
    project_owner? || project_admin?
  end

  def team_member?
    account&.same_team_or_owned_project?(project) || edit?
  end

  def update_status?
    account.comakery_admin?
  end
end
