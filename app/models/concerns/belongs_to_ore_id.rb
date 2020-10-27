module BelongsToOreId
  extend ActiveSupport::Concern

  included do
    before_validation :create_ore_id, on: :create
    before_validation :pending_for_ore_id, on: :create

    belongs_to :ore_id, optional: true
    validates :ore_id_id, presence: true, if: :ore_id?

    private

      def create_ore_id
        self.ore_id = (account.ore_id || account.create_ore_id) if ore_id?
      end

      def pending_for_ore_id
        self.state = :pending if ore_id? && address.nil?
      end
  end
end
