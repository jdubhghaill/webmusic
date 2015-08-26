class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.string :title
      t.string :artist
      t.string :compilation_artist
      t.string :album
      t.string :genre
      t.integer :year
      t.integer :track_number
      t.integer :disc_number
      t.string :filename
      t.string :location
      t.integer :filesize
      t.integer :duration
      t.timestamp :imported_on
      t.timestamp :last_played
      t.integer :play_count
      t.string :format

      t.timestamps null: false
    end
  end
end
