json.id            @track.id
json.title         @track.title
json.length        @track.length
json.duration      number_with_precision((@track.length / 60.0).round(2), precision: 2)
json.year          @track.year
json.genre         @track.genre
json.play_count    @track.play_count
json.type          "audio/#{@track.mimetype}"
json.src           "/api/tracks/#{@track.id}/data"
json.last_played   @track.last_played
json.created_at    @track.created_at
json.artist do
  json.id          @track.artist_id
  json.name        @track.artist_name
end
json.album do
  json.id          @track.album_id
  json.title       @track.album_title
end
json.track_number  @track.track_number
json.disc_number   @track.disc_number
json.collection_id @track.collection_id
