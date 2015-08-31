json.id            @album.id
json.title         @album.title
json.year          @album.year
json.genre         @album.genre
json.created_at    @album.created_at
json.has_image     !@album.image_type.nil?

json.artist do
  json.id          @album.artist_id
  json.name        @album.artist_name
end

json.discs @album.discs do |disc|
  json.id          disc.id
  json.number      disc.number

  json.tracks disc.tracks do |track|
    json.id            track.id
    json.title         track.title
    json.length        track.length
    json.duration      number_with_precision((track.length / 60.0).round(2), precision: 2)
    json.type          "audio/#{track.mimetype}"
    json.src           "/api/tracks/#{track.id}/data"
    json.track_number  track.track_number
    json.collection_id track.collection_id
  end
end
