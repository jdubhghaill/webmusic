app = angular.module 'webmusic', ['ngRoute', 'ngResource', 'ngAnimate', 'infinite-scroll', 'ui.bootstrap']

app.config ($httpProvider) ->
  authToken = $("meta[name=\"csrf-token\"]").attr("content")
  $httpProvider.defaults.headers.common["X-CSRF-TOKEN"] = authToken
  $httpProvider.defaults.headers.common["CONTENT_TYPE"] = "application/json"

app.config ($routeProvider, $locationProvider) ->
  $routeProvider.when('/queue', {
    templateUrl : '/assets/templates/queue.html',
    controller : 'QueueCtrl'
  }).when('/artists', {
    templateUrl : '/assets/templates/artists.html',
    controller : 'ArtistCtrl',
    reloadOnSearch: false
  }).when('/albums', {
    templateUrl : '/assets/templates/albums.html',
    controller : 'AlbumCtrl'
  }).when('/collections', {
    templateUrl : '/assets/templates/collections.html',
    controller : 'CollectionCtrl'
  }).when('/collections/:id', {
    templateUrl : '/assets/templates/collection.html',
    controller : 'CollectionCtrl'
  }).when('/collection-errors/:id', {
    templateUrl : '/assets/templates/collection_error.html',
    controller : 'CollectionErrorCtrl'
  }).when('/albums/:id', {
    templateUrl : '/assets/templates/album.html',
    controller : 'AlbumCtrl'
  }).otherwise({
    redirectTo: '/artists'
  });
  $locationProvider.html5Mode(true);
  return

app.service 'alertService', ['$timeout'
  ($timeout) ->
    alerts = []

    getAlerts: ->
      alerts

    add: (message) ->
      alerts.push({message: message})
      $timeout(
        ->
          alerts.shift()
        , 2000
      )
]

app.service 'playerService', ['$resource', '$timeout', 'alertService'
  ($resource, $timeout, alertService) ->
    playlist = []
    player = null

    getPlayer: ->
      player

    setPlayer: (p) ->
      player = p

    getPlaylist: ->
      playlist

    add: (data) ->
      data = angular.fromJson(angular.toJson(data))
      Array.prototype.push.apply(playlist, data)
      alertService.add("Added #{data.length} tracks to the queue")

    add_discs: (data) ->
      data = angular.fromJson(angular.toJson(data))
      tracks = []
      tracks.push(t) for t in d.tracks for d in data
      this.add(tracks)

    load: (data, playIndex) ->
      player.audio.stop()
      playlist.length = 0
      data = angular.fromJson(angular.toJson(data))
      angular.copy(data, playlist)
      $timeout(
        ->
          player.audio.play(playIndex)
        , 500
      )

    load_discs: (data, discIndex, playIndex) ->
      tracks = []
      tracks.push(t) for t in d.tracks for d in data

      size = 0
      if discIndex > 0
        size += d.tracks.length for d in data[0..(discIndex - 1)]
      playIndex = size + playIndex

      this.load(tracks, playIndex)

]

app.factory 'CollectionErrorService', ($resource) ->
  class CollectionErrorService
    constructor: ->
      @service = $resource('/api/collection_errors/:id', {id: '@id'})

    get: (id) ->
      @service.get({id: id})

app.factory 'CollectionService', ($resource, $q) ->
  class CollectionService
    constructor: ->
      @service = $resource('/api/collections/:id', {id: '@id'})

    create: (attrs) ->
      deferred = $q.defer()
      new @service(collection: attrs).$save (collection) ->
        deferred.resolve(collection)
      deferred.promise

    get: (id) ->
      @service.get({id: id})

    all: ->
      @service.query()

app.factory 'ArtistService', ($resource) ->
  class ArtistService
    constructor: ->
      @service = $resource('/api/artists/:id', {id: '@id'}, {
        tracks: {method: 'GET', url: '/api/artists/:id/tracks', isArray: true}
      })

    get: (id) ->
      @service.get({id: id})

    all: ->
      @service.query()

    tracks: (id) ->
      @service.tracks({id: id})

app.factory 'AlbumService', ($resource) ->
  class AlbumService
    constructor: ->
      @service = $resource('/api/albums/:id', {id: '@id'})

    get: (id) ->
      @service.get({id: id})

    all: (offset) ->
      @service.query({offset: offset})

app.controller 'NavCtrl', ($scope, $location, $timeout) ->
  $scope.isAlbums = ->
    if $location.path() == "/albums"
      return true
    false

  $scope.isArtists = ->
    if $location.path() == "/artists"
      return true
    false

  $scope.isSettings = ->
    if $location.path() == "/collections"
      return true
    false

app.controller 'QueueCtrl', ($scope, $window, playerService) ->
  $scope.realPlaylist = playerService.getPlaylist()
  $scope.player = playerService.getPlayer()
  $scope.playlist = angular.copy($scope.realPlaylist)

  $scope.back = ->
    $window.history.back()

  $scope.remove = (index) ->
    $scope.playlist.splice(index, 1)
    $scope.realPlaylist.splice(index, 1)

  $scope.clear = ->
    $scope.playlist.length = 0
    $scope.realPlaylist.length = 0

  $scope.play = (index) ->
    $scope.player.audio.play(index)

app.controller 'AlertCtrl', ($scope, alertService) ->
  $scope.alerts = alertService.getAlerts()

app.controller 'PlayerCtrl', ($scope, $location, playerService, $timeout) ->
  $scope.audio = null
  $scope.playlist = playerService.getPlaylist()
  $scope.repeat = false
  playerService.setPlayer($scope)

  $scope.gotoQueue = ->
    $location.path("/queue")

  $scope.percent = ->
    if !$scope.audio || !$scope.audio.formatTime
      return 0
    ($scope.audio.currentTime / $scope.audio.duration) * 100

  $scope.progress = ->
    {width: "#{$scope.percent()}%"}

  $scope.play = ->
    $scope.audio.play()

  $scope.atFirst = ->
    if $scope.playlist.length == 0 || $scope.audio.currentTrack == 1
      return true
    false

  $scope.atLast = ->
    if $scope.playlist.length == 0 || $scope.audio.currentTrack == $scope.playlist.length
      return true
    false

  $timeout( ->
    $scope.audio.on('ended', (event) ->
      if $scope.repeat and $scope.audio.ended
        $scope.audio.play(0)
    )
  )

app.controller 'CollectionErrorCtrl', ($scope, $routeParams, CollectionErrorService) ->
  $scope.collectionErrorService = new CollectionErrorService()
  if $routeParams.id
    $scope.collectionError = $scope.collectionErrorService.get($routeParams.id)

app.controller 'CollectionCtrl', ($scope, $interval, $routeParams, $location, CollectionService) ->
  $scope.collectionService = new CollectionService()
  if $routeParams.id
    $scope.collection = $scope.collectionService.get($routeParams.id)
  else
    $scope.collections = $scope.collectionService.all()

  $scope.create = ->
    $scope.collectionService.create(path: $scope.input_location).then(
      (col) ->
        index = $scope.collections.push(col) - 1
        if col.exists
          inter = $interval(
            ->
              $scope.collectionService.get(col.id).$promise.then(
                (c) ->
                  $scope.collections[index] = c
                  if !c.scanning
                    $interval.cancel(inter)
                    inter = null
              )
            , 2000
          )
    )
    $scope.input_location = ''

  $scope.openCollection = (id) ->
    $location.path("/collections/#{id}")

app.controller 'ArtistCtrl', ($scope, $routeParams, $location, ArtistService, playerService, AlbumService) ->
  $scope.loading = true
  $scope.scroll = false
  $scope.tracks = null
  $scope.artistService = new ArtistService()
  $scope.albumService = new AlbumService()
  $scope.artistService.all().$promise.then (
    (artists) ->
      $scope.artists = artists
      $scope.loading = false
  )
  if $routeParams.id
    $scope.artistService.get($routeParams.id).$promise.then(
      (artist) ->
        $scope.artist = artist
        $scope.scroll = true
    )

  $scope.openArtist = (index) ->
    $scope.artistService.get($scope.artists[index].id).$promise.then(
      (artist) ->
        $scope.artist = $scope.artists[index] = artist
        $location.search("id","#{artist.id}")
    )

  $scope.openAlbum = (id) ->
    $location.url("/albums/#{id}")

  $scope.load = ->
    $scope.artistService.tracks($scope.artist.id).$promise.then(
      (tracks) ->
        playerService.load(tracks, 0)
    )

  $scope.queue = ->
    $scope.artistService.tracks($scope.artist.id).$promise.then(
      (tracks) ->
        playerService.add(tracks)
    )

  $scope.loadAlbum = (id) ->
    $scope.albumService.get(id).$promise.then(
      (album) ->
        playerService.load_discs(album.discs, 0)
    )

  $scope.queueAlbum = (id) ->
    $scope.albumService.get(id).$promise.then(
      (album) ->
        playerService.add_discs(album.discs)
    )

app.controller 'AlbumCtrl', ($scope, $routeParams, $location, AlbumService, playerService) ->
  $scope.loading = true
  $scope.complete = false
  $scope.albumService = new AlbumService()
  if $routeParams.id
    $scope.album = $scope.albumService.get($routeParams.id)
  else
    $scope.albumService.all(0).$promise.then(
      (albums) ->
        $scope.albums = albums
        $scope.loading = false
    )

  $scope.loadAlbums = ->
    $scope.loading = true
    $scope.albumService.all($scope.albums.length).$promise.then(
      (albums) ->
        if albums.length < 100
          $scope.complete = true
        $scope.albums = $scope.albums.concat(albums)
        $scope.loading = false
    )

  $scope.load = (id) ->
    if id
      $scope.albumService.get(id).$promise.then(
        (album) ->
          playerService.load_discs(album.discs, 0, 0)
      )
    else
      playerService.load_discs($scope.album.discs, 0, 0)

  $scope.queue = (id) ->
    if id
      $scope.albumService.get(id).$promise.then(
        (album) ->
          playerService.add_discs(album.discs)
      )
    else
      playerService.add_discs($scope.album.discs)

  $scope.playTrack = (discIndex, index) ->
    playerService.load_discs($scope.album.discs, discIndex, index)

  $scope.queueTrack = (discIndex, index) ->
    a = []
    a.push($scope.album.discs[discIndex].tracks[index])
    playerService.add(a)

  $scope.openAlbum = (id) ->
    $location.path("/albums/#{id}")

app.directive "artistScroll", ($timeout) ->
  restrict: "A",
  link: (scope, element, attrs) ->
    scope.$watch(attrs.muScroll, (value) ->
      if value
        $timeout( ->
          w = $(window).height() / 2
          $("#artistsNav").scrollTop($("#artistsNav").scrollTop() + $("#artistsNav .active").position().top - w);
        , 0)
    )

app.directive "artistDetails", () ->
  restrict: "A"
  controller: ($scope) ->

  templateUrl: "/assets/templates/artist.html"
