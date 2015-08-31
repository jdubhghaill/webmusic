json.id            @artist.id
json.name          @artist.name
json.created_at    @artist.created_at
json.album_count   @artist.album_count

json.compilations  @artist.compilations do |album|
  json.id            album.id
  json.title         album.title
  json.year          album.year
  json.has_image     !album.image_type.nil?
end

json.albums        @artist.albums do |album|
  json.id            album.id
  json.title         album.title
  json.year          album.year
  json.has_image     !album.image_type.nil?
end
