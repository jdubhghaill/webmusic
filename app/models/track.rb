class Track < ActiveRecord::Base
  default_scope {order('track_number ASC')}

  belongs_to :disc
  belongs_to :album
  belongs_to :artist
  belongs_to :collection

  validates :path,  :presence => true
end
