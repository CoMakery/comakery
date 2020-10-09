module Api::V1::Concerns::RequiresWhitelabelMission
  extend ActiveSupport::Concern
  include Api::V1::Concerns::Authorizable

  included do
    before_action :requires_whitelabel_mission

    def requires_whitelabel_mission
      unless whitelabel_mission
        @errors = { authentication: 'Requires whitelabel' }

        render 'api/v1/error.json', status: :unauthorized
      end
    end
  end
end
