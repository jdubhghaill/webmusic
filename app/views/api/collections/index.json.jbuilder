json.array! @collections do |collection|
  json.id            collection.id
  json.path          collection.path
  json.last_scan     collection.last_scan
  json.created_at    collection.created_at
  json.updated_at    collection.updated_at
  json.exists        collection.exists
  json.scanning      collection.scanning
  json.track_count   collection.track_count

  json.collection_errors collection.collection_errors do |error|
    json.path        error.path
    json.message     error.message
  end
end
