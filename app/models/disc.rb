class Disc < ActiveRecord::Base
  default_scope {order('number ASC')}

  has_many :tracks
  belongs_to :album
end
