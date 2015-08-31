class AddLocationToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :location, :string
  end
end
