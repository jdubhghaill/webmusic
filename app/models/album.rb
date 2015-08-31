class Album < ActiveRecord::Base
  default_scope {order('title ASC')}

  belongs_to :artist
  has_many :tracks
  has_many :discs
end
