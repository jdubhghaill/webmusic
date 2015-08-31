json.array! @albums do |album|
  json.id            album.id
  json.title         album.title
  json.year          album.year
  json.genre         album.genre
  json.created_at    album.created_at
  json.has_image     !album.image_type.nil?

  json.artist do
    json.id          album.artist_id
    json.name        album.artist_name
  end
end
