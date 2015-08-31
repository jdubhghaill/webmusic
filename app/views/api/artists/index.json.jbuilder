json.array! @artists do |artist|
  json.id            artist.id
  json.name          artist.name
  json.created_at    artist.created_at
  json.album_count   artist.album_count
  json.has_image     !artist.image_type.nil?
end
