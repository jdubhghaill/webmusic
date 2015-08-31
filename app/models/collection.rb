require 'taglib'

class Collection < ActiveRecord::Base
  has_many :tracks, :dependent => :destroy
  has_many :collection_errors, :dependent => :destroy
  validates :path, :presence => true

  def exists?
    if Dir.exists? self.path
      exists = true
    else
      exists = false
    end
    exists
  end

  def scan
    start_time = Time.new
    print "\nscan starting\n"
    self.track_count = 0
    self.scanning = true
    self.save!
    scan_dir(self.path)
    self.scanning = false
    self.save!
    end_time = Time.new
    period = ((end_time - start_time) / 1.minute)
    print "scan finished in #{period} minutes\n"
    track_count
  end

private
  def scan_dir(directory)
    albums = {}
    image = nil
    image_type = nil
    contents = Dir.entries(directory)
    contents.each do |entry|
      begin
        unless entry == "." || entry == ".."
          if !entry.valid_encoding?
            raise "file has invalid encoding"
          end
          path = File.join(directory, entry)
          if File.directory?(path) && !File.symlink?(path)
            scan_dir(path)
          elsif entry =~ /.*mp3$|.*ogg$/
            location = path.sub(self.path, '')
            t = process_file(path, location, entry)
            add_to_albums_hash(t, albums)
          elsif entry =~ /.*jpg$|.*png$|.*jpeg$/ && image.nil?
            File.open(path) { |f|
              image = f.read
            }
            if entry =~ /.*jpg$|.*jpeg$/
              image_type = "image/jpg"
            else
              image_type = "image/png"
            end
          end
        end
      rescue => e
        print e.backtrace.join("\n")
        logger.error "error in processing file #{entry} in directory #{directory}\n#{e.message}"
        location = File.join(directory, entry)
        ce = CollectionError.new
        ce.path = location.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        ce.message = e.message
        ce.collection = self
        ce.save!
      end
    end
    create_albums(albums, image, image_type)
  end

  def create_albums(albums, image, image_type)
    albums.each do |key, value|
      if key == nil || key.strip.empty?
        next
      end

      album_title = value[:title]
      adisc = value[:discs].keys[0]
      album_year = value[:discs][adisc][:tracks][0].year
      album_genre = value[:discs][adisc][:tracks][0].genre
      album_artist = nil
      if value[:artists].size > 1
        album_artist = 0
      else
        album_artist = value[:artists].keys[0]
      end

      album = get_album(album_title, album_artist, album_year, album_genre)
      if value[:image].nil?
        album.image = image
        album.image_type = image_type
      else
        album.image = value[:image]
        album.image_type = value[:image_type]
      end
      value[:discs].each do |discnumber, d|
        disc = Disc.new
        disc.number = discnumber
        disc.album = album
        disc.save!
        d[:tracks].each do |track|
          track.disc = disc
          track.album = album
          track.save!
        end
      end
      self.save!
    end
  end

  def add_to_albums_hash(track_hash, albums)
    track = track_hash[:track]
    discnum = track_hash[:discnumber]
    if albums.has_key? track.album_title
      album = albums[track.album_title]
      if album[:discs].has_key? discnum
        album[:discs][discnum][:tracks] << track
      else
        album[:discs][discnum] = {:tracks => [track]}
      end

      unless album[:artists].has_key? track.artist.id
        album[:artists][track.artist.id] = track.artist.name
      end
    else
      albums[track.album_title] = {
        :title => track.album_title,
        :discs => {discnum => {:tracks => [track]}},
        :artists => {track.artist.id => track.artist.name},
        :image => track_hash[:image],
        :image_type => track_hash[:image_type],
        :album => nil
      }
    end
  end

  def process_file(path, location, filename)
    track_hash = nil

    if path =~ /.*ogg$/
      TagLib::Ogg::Vorbis::File.open(path) do |fileref|
        tag = fileref.tag
        unless tag.empty?
          self.track_count += 1
          artist = get_artist(tag.artist.strip)
          track = Track.new
          track.location = location
          track.filename = filename
          track.artist = artist
          track.artist_name = artist.name.strip
          track.album_title = tag.album.strip
          track.collection = self
          track.track_number = tag.track
          track.path = path
          track.genre = tag.genre.strip
          track.play_count = 0
          track.title = tag.title.strip
          track.year = tag.year.to_i
          track.mimetype = "ogg"
          track.length = fileref.audio_properties.length
          ogg_tag = fileref.tag.field_list_map
          discnumber = 0
          if tag.contains? "DISCNUMBER"
            num = ogg_tag["DISCNUMBER"][0]
            discnumber = num.sub(/\/.*/, '').to_i
          end
          track_hash = {:discnumber => discnumber, :track => track, :image => nil, :image_type => nil}
        end
      end
    elsif path =~ /.*mp3$/
      TagLib::MPEG::File.open(path) do |fileref|
        self.track_count += 1
        tag = fileref.tag
        artist = get_artist(tag.artist.strip)
        track = Track.new
        track.artist = artist
        track.artist_name = artist.name.strip
        track.album_title = tag.album.strip
        track.collection = self
        track.track_number = tag.track
        track.path = path
        track.genre = tag.genre.strip
        track.play_count = 0
        track.title = tag.title.strip
        track.year = tag.year.to_i
        track.mimetype = "mpeg"
        track.length = fileref.audio_properties.length
        discnumber = 0
        image = nil
        image_type = nil
        unless fileref.id3v2_tag.nil?
          tpos = fileref.id3v2_tag.frame_list("TPOS")
          if !tpos.nil? && tpos.length > 0
            num = tpos[0].to_string
            discnumber = num.sub(/\/.*/, '').to_i
          end

          apic = fileref.id3v2_tag.frame_list('APIC')
          if !apic.nil? && apic.length > 0
            image = apic.first.picture
            image_type = apic.first.mime_type
          end
        end
        track_hash = {:discnumber => discnumber, :track => track, :image => image, :image_type => image_type}
      end
    end
    track_hash
  end

  def get_artist(name)
    return nil if name == nil
    artist = Artist.where("name = ?", name).first
    if artist == nil
      artist = Artist.new
      artist.name = name.strip
      artist.sort = create_artist_sort(name)
      artist.save!
    end
    return artist
  end

  def create_artist_sort(name)
    sort = name.strip.downcase
    if sort.start_with? "the "
      sort.slice!(0..3)
    end
    sort.strip
  end

  def get_album(title, artist, year, genre)
    return nil if title == nil
    album = Album.where("title = :title and artist_id = :artist and year = :year",
             {title: title, artist: artist, year: year}).first
    if album == nil
      album = Album.new
      album.title = title
      album.year = year
      album.genre = genre
      album.artist = Artist.find(artist)
      if artist == 0
        album.artist_name = "Various Artists"
      else
        album.artist_name = album.artist.name
        album.artist.album_count += 1
        album.artist.save
      end
    end
    return album
  end

end
