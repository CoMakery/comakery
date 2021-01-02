class RefactorProjects < ActiveRecord::Migration[5.1]
  def change
    # remove_column :projects, :slack_team_id, :string

    # Commenting these column removels because deleting the migrations to add these attrs to project tables
    # remove_column :projects, :slack_team_name, :string
    # remove_column :projects, :slack_team_domain, :string
    # remove_column :projects, :slack_team_image_34_url, :string
    # remove_column :projects, :slack_team_image_132_url, :string
    rename_column :accounts, :image_content_zise, :image_content_size
    rename_column :projects, :owner_account_id, :account_id
    add_column :projects, :image_filename, :string
    add_column :projects, :image_content_size, :string
    add_column :projects, :image_content_type, :string
    change_column_null :projects, :slack_team_id, true
  end
end
