class Mission < ApplicationRecord
  default_scope { order(display_order: :asc) }

  attachment :logo
  attachment :image

  has_many :projects, inverse_of: :mission
  has_many :public_projects, -> { public_listed }, class_name: 'Project'
  has_many :leaders, through: :public_projects, source: :account
  has_many :tokens, through: :public_projects, source: :token
  enum status: %i[active passive]

  after_create :assign_display_order
  validates :name, :subtitle, :description, :logo, :image, presence: true
  validates :name, length: { maximum: 100 }
  validates :subtitle, length: { maximum: 140 }
  validates :description, length: { maximum: 500 }

  def serialize
    as_json(only: %i[id name token_id subtitle description status display_order]).merge(
      logo_preview: logo.present? ? Refile.attachment_url(self, :logo, :fill, 150, 100) : nil,
      image_preview: image.present? ? Refile.attachment_url(self, :image, :fill, 100, 100) : nil
    )
  end

  private

  def assign_display_order
    self.display_order = id
    save
  end
end
