class Artist < ActiveRecord::Base
  default_scope {order('sort ASC')}

  has_many :albums
  has_many :tracks

  def compilations
    Album.joins(:tracks).where("albums.artist_id = ? AND tracks.artist_id = ?", 0, self.id).group("albums.id")
  end
end
