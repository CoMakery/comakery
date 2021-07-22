class PagesController < ApplicationController
  before_action :unavailable_for_whitelabel

  skip_before_action :require_login
  skip_before_action :require_email_confirmation
  skip_after_action :verify_authorized

  layout 'legacy', except: [:featured]
  layout 'layout_new_styling', only: [:styleguide]

  def featured # rubocop:todo Metrics/CyclomaticComplexity
    top_missions = Mission.active.without_whitelabel.with_attached_image.first(4)
    more_missions = Mission.active.without_whitelabel.with_attached_image.offset(4).limit(10)

    flash[:warning] = 'Please confirm your email address to continue' if current_account && !current_account&.confirmed? && !current_account&.valid_and_underage?
    @props = {
      csrf_token: form_authenticity_token,
      top_missions: top_missions.map { |mission| featured_mission_props(mission) },
      more_missions: more_missions.map { |mission| more_mission_props(mission) },
      is_confirmed: current_account.nil? ? true : current_account.confirmed?
    }
  end

  def contribution_licenses
    case params[:type]
    when 'CP'
      type = 'CP'
    when 'RP'
      type = 'RP'
    else
      return redirect_to('/404.html')
    end

    path = Rails.root.join('lib', 'assets', 'contribution_licenses', "#{type}-*.md")
    license = Dir.glob(path).max_by { |f| File.mtime(f) }
    @license_md = File.read(license)
  end

  def styleguide
    return redirect_to :root unless Rails.env.development?
  end

  private

    def featured_mission_props(mission)
      mission.as_json(only: %i[id name description]).merge(
        mission_url: mission_url(mission),
        image_url: mission_image_path(mission, 312),
        projects: mission.projects.public_listed.active.map do |project|
          project.as_json(only: %i[id title]).merge(
            involved: current_account&.involved?(project.id)
          )
        end
      )
    end

    def more_mission_props(mission)
      mission.as_json(only: %i[id name]).merge(
        mission_url: mission_url(mission),
        image_url: mission_image_path(mission, 231),
        projects_count: mission.projects.public_listed.active.count
      )
    end

    def mission_image_path(mission, size)
      GetImageVariantPath.call(
        attachment: mission.image,
        resize_to_fill: [size, size]
      ).path
    end
end
