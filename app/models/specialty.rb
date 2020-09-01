# Think of the contents of this table as an enumeration (enum) that can serve as a join between tables
class Specialty < ActiveRecord::Base
  has_many :accounts # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :interests # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :award_types # rubocop:todo Rails/HasManyOrHasOneDependent

  validates :name, uniqueness: true # rubocop:todo Rails/UniqueValidationWithoutIndex

  # To be called when the application loads in config/initalizers/specialty_values
  # Must be able to be run every time the application starts up without changing the ids or creating duplicate entries
  def self.initializer_setup
    Specialty.where(id: 1).first_or_create(name: 'Audio Or Video Production')
    Specialty.where(id: 2).first_or_create(name: 'Community Development')
    Specialty.where(id: 3).first_or_create(name: 'Data Gathering')
    Specialty.where(id: 4).first_or_create(name: 'Marketing & Social')
    Specialty.where(id: 5).first_or_create(name: 'Software Development')
    Specialty.where(id: 6).first_or_create(name: 'Design')
    Specialty.where(id: 7).first_or_create(name: 'Writing')
    Specialty.where(id: 8).first_or_create(name: 'Research')
    Specialty.where(id: 9).first_or_create(name: 'General')
  end

  def self.default
    Specialty.find_or_create_by(name: 'General')
  end
end
