class Mission < ApplicationRecord
  include PrepareImage

  default_scope { order(display_order: :asc) }

  has_one_attached_and_prepare_image :logo
  has_one_attached_and_prepare_image :image
  has_one_attached_and_prepare_image :whitelabel_logo
  has_one_attached_and_prepare_image :whitelabel_logo_dark
  has_one_attached_and_prepare_image :whitelabel_favicon

  has_many :projects, inverse_of: :mission # rubocop:todo Rails/HasManyOrHasOneDependent
  # rubocop:todo Rails/InverseOf
  has_many :unarchived_projects, -> { where.not visibility: :archived }, source: :projects, class_name: 'Project'
  # rubocop:enable Rails/InverseOf
  has_many :public_projects, -> { public_listed }, class_name: 'Project' # rubocop:todo Rails/InverseOf
  has_many :leaders, through: :public_projects, source: :account
  has_many :tokens, through: :public_projects, source: :token
  has_many :award_types, through: :projects
  has_many :ready_award_types, -> { where state: 'public' }, through: :unarchived_projects, source: :award_types, class_name: 'AwardType'
  has_many :published_awards, through: :ready_award_types, source: :awards, class_name: 'Award'
  has_many :awards, through: :award_types
  has_many :interested, -> { distinct }, through: :public_projects
  has_many :project_roles, through: :public_projects

  # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :managed_accounts, class_name: 'Account', foreign_key: 'managed_mission_id' # rubocop:todo Rails/InverseOf
  # rubocop:enable Rails/HasManyOrHasOneDependent

  enum status: { active: 0, passive: 1 }

  scope :with_all_attached_images, lambda {
    with_attached_logo
      .with_attached_image
      .with_attached_whitelabel_logo
      .with_attached_whitelabel_logo_dark
      .with_attached_whitelabel_favicon
  }

  scope :without_whitelabel, -> { where(whitelabel: false) }

  after_create :assign_display_order
  after_save :set_whitelabel_for_projects

  validates :name, :subtitle, :description, :logo, :image, presence: true
  validates :name, length: { maximum: 100 }
  validates :subtitle, length: { maximum: 140 }
  validates :description, length: { maximum: 500 }
  validate :whitelabel_api_public_keys_cannot_be_overwritten

  before_save :populate_api_key, if: -> { whitelabel }

  def serialize
    as_json(only: %i[id name token_id subtitle description status display_order])
      .merge(
        logo_preview: GetImageVariantPath.call(attachment: logo, resize_to_fill: [150, 100]).path,
        image_preview: GetImageVariantPath.call(attachment: image, resize_to_fill: [100, 100]).path,
        stats: stats
      )
  end

  def stats
    {
      projects: unarchived_projects.size,
      batches: ready_award_types.size,
      tasks: published_awards.in_progress.size,
      project_roles: project_roles.size
    }
  end

  private

    def assign_display_order
      self.display_order = id
      save
    end

    def set_whitelabel_for_projects
      projects.update(whitelabel: whitelabel)
    end

    def whitelabel_api_public_keys_cannot_be_overwritten
      errors.add(:whitelabel_api_public_key, 'cannot be overwritten') if whitelabel_api_public_key_changed? && whitelabel_api_public_key_was.present?
      errors.add(:wallet_recovery_api_public_key, 'cannot be overwritten') if wallet_recovery_api_public_key_changed? && wallet_recovery_api_public_key_was.present?
    end

    def populate_api_key
      # 24 bytes = 32 characters base64 string

      self.whitelabel_api_key ||= SecureRandom.base64(24)
    end
end
