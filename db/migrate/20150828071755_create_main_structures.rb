class CreateMainStructures < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string :name
      t.binary :image
      t.string :sort
      t.integer :album_count, default: 0

      t.timestamps
    end
    add_index("artists", ["sort"], unique: true)

    create_table :albums do |t|
      t.string :title
      t.references :artist
      t.string "artist_name"
      t.integer :year
      t.string :genre
      t.binary :image
      t.string "image_type"
      
      t.timestamps
    end
    add_index :albums, :artist_id
    add_index :albums, :title

    create_table :collections do |t|
      t.string :path
      t.string :webserver_alias
      t.timestamp :last_scan
      t.boolean :exists
      t.boolean :scanning
      t.integer :track_count

      t.timestamps
    end

    create_table :collection_errors do |t|
      t.string :path
      t.string :message
      t.references :collection

      t.timestamps
    end
    add_index :collection_errors, :collection_id

    create_table :discs do |t|
      t.integer :number
      t.references :album

      t.timestamps
    end
    add_index :discs, :album_id

    change_table :tracks do |t|
      t.remove :imported_on, 
               :artist,
               :album, 
               :filesize,
               :location, 
               :duration, 
               :format
      t.string :path
      t.string :album_title
      t.string  :artist_name
      t.references :album
      t.references :artist
      t.references :disc
      t.references :collection
      t.integer :length
      t.string :mimetype
    end
    add_index :tracks, :album_id
    add_index :tracks, :artist_id
    add_index :tracks, :collection_id
    add_index :tracks, :disc_id

  end
end
