class AddImageTypeToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :image_type, :string
  end
end
