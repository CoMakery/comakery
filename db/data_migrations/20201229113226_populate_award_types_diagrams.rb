class PopulateAwardTypesDiagrams < ActiveRecord::DataMigration
  def up
    AwardType.find_each do |award_type|
      next if award_type.diagram_id.blank?

      begin
        diagram = Refile.store.get(award_type.diagram_id).download
        award_type.diagram.attach(
          io: diagram,
          filename: award_type.diagram_filename || 'diagram'
        )
      rescue StandardError
        next
      end
    end
  end

  def down; end
end
