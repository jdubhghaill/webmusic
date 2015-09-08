class AddScannedToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :scanned, :boolean
  end
end
