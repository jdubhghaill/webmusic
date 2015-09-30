app = angular.module 'webmusic',
  ['ngRoute',
   'ngResource',
   'ngAnimate',
   'infinite-scroll',
   'ui.bootstrap',
   'Devise'
  ]

app.config ['$httpProvider'
  ($httpProvider) ->
    $httpProvider.defaults.headers.common["CONTENT_TYPE"] = "application/json"
    $httpProvider.defaults.withCredentials = true;
]

app.config ['$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider.when('/sign_in', {
      templateUrl : '/assets/templates/sign_in.html',
      controller : 'UserCtrl'
    }).when('/queue', {
      templateUrl : '/assets/templates/queue.html',
      controller : 'QueueCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/artists', {
      templateUrl : '/assets/templates/artists.html',
      controller : 'ArtistCtrl',
      reloadOnSearch: false,
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/albums', {
      templateUrl : '/assets/templates/albums.html',
      controller : 'AlbumCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/collections', {
      templateUrl : '/assets/templates/collections.html',
      controller : 'CollectionCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/collections/:id', {
      templateUrl : '/assets/templates/collection.html',
      controller : 'CollectionCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/collection-errors/:id', {
      templateUrl : '/assets/templates/collection_error.html',
      controller : 'CollectionErrorCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).when('/albums/:id', {
      templateUrl : '/assets/templates/album.html',
      controller : 'AlbumCtrl',
      resolve:
        auth: ['Auth', '$location',
          (Auth, $location) ->
            Auth.currentUser().then(
              (user) ->

            , (error) ->
              $location.path('/sign_in');
            )
        ]
    }).otherwise({
      redirectTo: '/sign_in'
    })
    $locationProvider.html5Mode(true)
    return
]

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
    audioPlayer = null

    setAudioPlayer: (newAudioPlayer) ->
      audioPlayer = newAudioPlayer

    play: ->
      audioPlayer.play()

    playPause: ->
      audioPlayer.playPause()

    playing: ->
      audioPlayer.playing()

    isReady: ->
      audioPlayer.isReady()

    currentTime: ->
      audioPlayer.currentTime()

    totalTime: ->
      audioPlayer.totalTime()

    getCurrentTrack: ->
      audioPlayer.getCurrentTrack()

    setTrack: (trackNumber) ->
      audioPlayer.setTrack(trackNumber)

    getPlaylist: ->
      playlist

    prev: ->
      audioPlayer.prev()

    next: ->
      audioPlayer.next()

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
      playlist.length = 0
      data = angular.fromJson(angular.toJson(data))
      angular.copy(data, playlist)
      this.currentTrack = 0
      this.setTrack(playIndex)
      this.play()

    load_discs: (data, discIndex, playIndex) ->
      tracks = []
      tracks.push(t) for t in d.tracks for d in data

      size = 0
      if discIndex > 0
        size += d.tracks.length for d in data[0..(discIndex - 1)]
      playIndex = size + playIndex

      this.load(tracks, playIndex)

]

app.factory 'CollectionErrorService', ['$resource'
  ($resource) ->
    class CollectionErrorService
      constructor: ->
        @service = $resource('/api/collection_errors/:id', {id: '@id'})

      get: (id) ->
        @service.get({id: id})
]

app.factory 'CollectionService', ['$resource', '$q'
  ($resource, $q) ->
    class CollectionService
      constructor: ->
        @service = $resource('/api/collections/:id', {id: '@id'}, {
          scan: {method: 'PUT', url: '/api/collections/:id/scan'}
        })

      create: (attrs) ->
        deferred = $q.defer()
        new @service(collection: attrs).$save (collection) ->
          deferred.resolve(collection)
        deferred.promise

      get: (id) ->
        @service.get({id: id})

      all: ->
        @service.query()

      scan: (id) ->
        @service.scan({id: id})
]

app.factory 'ArtistService', ['$resource'
  ($resource) ->
    class ArtistService
      constructor: ->
        @service = $resource('/api/artists/:id', {id: '@id'}, {
          tracks: {method: 'GET', url: '/api/artists/:id/tracks', isArray: true}
        })

      get: (id) ->
        @service.get({id: id})

      query: (page) ->
        @service.query({page: page, page_size: 50})

      tracks: (id) ->
        @service.tracks({id: id})
]

app.factory 'AlbumService', ['$resource'
  ($resource) ->
    class AlbumService
      constructor: ->
        @service = $resource('/api/albums/:id', {id: '@id'})

      get: (id) ->
        @service.get({id: id})

      all: (offset) ->
        @service.query({offset: offset})
]

app.controller 'MainCtrl', ['$scope', '$location', 'Auth', 'alertService',
  ($scope, $location, Auth, alertService) ->
    $scope.isAuthenticated = () ->
      Auth.isAuthenticated()

    $scope.signOut = () ->
      Auth.logout().then((oldUser) ->
        $location.path("/sign_in")
      , (error) ->
        alertService.add("Error on logging out #{error}")
      )
]

app.controller 'UserCtrl', ['$scope', '$location', 'Auth',
  ($scope, $location, Auth) ->
    config =
      headers:
        'X-HTTP-Method-Override': 'POST'

    $scope.submitLogin  = (loginForm) ->
      Auth.login(loginForm, config).then(
        (user) ->
          console.log(user)
          $location.path('/artists')
        , (error) ->
          $scope.error = error
      )
]

app.controller 'NavCtrl', ['$scope', '$location', '$timeout'
  ($scope, $location, $timeout) ->
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
]

app.controller 'QueueCtrl', ['$scope', '$window', 'playerService'
  ($scope, $window, playerService) ->
    $scope.realPlaylist = playerService.getPlaylist()
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
      playerService.play(index)

    $scope.currentTrack = () ->
      playerService.getCurrentTrack()

    $scope.playing = () ->
      playerService.playing()
]

app.controller 'AlertCtrl', ['$scope', 'alertService'
  ($scope, alertService) ->
    $scope.alerts = alertService.getAlerts()
]

app.controller 'CollectionErrorCtrl', ['$scope', '$routeParams', 'CollectionErrorService'
  ($scope, $routeParams, CollectionErrorService) ->
    $scope.collectionErrorService = new CollectionErrorService()
    if $routeParams.id
      $scope.collectionError = $scope.collectionErrorService.get($routeParams.id)
]

app.controller 'CollectionCtrl', ['$scope', '$interval', '$routeParams', '$location', 'CollectionService'
  ($scope, $interval, $routeParams, $location, CollectionService) ->
    $scope.collectionService = new CollectionService()
    if $routeParams.id
      $scope.collection = $scope.collectionService.get($routeParams.id)
    else
      $scope.collections = $scope.collectionService.all()

    $scope.scan = () ->
      $scope.collectionService.scan($scope.collection.id).$promise.then(
        inter = $interval(
          ->
            $scope.collectionService.get($scope.collection.id).$promise.then(
              (c) ->
                $scope.collection = c
                if !c.scanning
                  $interval.cancel(inter)
                  inter = null
            )
          , 2000
        )
      )

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
]

app.controller 'ArtistCtrl', ['$scope', '$routeParams', '$location', 'ArtistService', 'playerService', 'AlbumService'
  ($scope, $routeParams, $location, ArtistService, playerService, AlbumService) ->
    $scope.loading = true
    $scope.busy = true
    $scope.tracks = null
    $scope.page = 1
    $scope.artistService = new ArtistService()
    $scope.albumService = new AlbumService()
    $scope.artistService.query($scope.page).$promise.then (
      (artists) ->
        $scope.artists = artists
        $scope.loading = false
        $scope.busy = false
    )
    if $routeParams.id
      $scope.artistService.get($routeParams.id).$promise.then(
        (artist) ->
          $scope.artist = artist
          $scope.scroll = false
      )

    $scope.scroll = () ->
      $scope.busy = true
      $scope.page += 1
      $scope.artistService.query($scope.page).$promise.then (
        (artists) ->
          Array.prototype.push.apply($scope.artists, artists)
          if artists.length == 50
            $scope.busy = false
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
]

app.controller 'AlbumCtrl', ['$scope', '$routeParams', '$location', 'AlbumService', 'playerService'
  ($scope, $routeParams, $location, AlbumService, playerService) ->
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
]

app.directive "artistScroll", ['$timeout'
  ($timeout) ->
    restrict: "A",
    link: (scope, element, attrs) ->
      scope.$watch(attrs.muScroll, (value) ->
        if value
          $timeout( ->
            w = $(window).height() / 2
            $("#artistsNav").scrollTop($("#artistsNav").scrollTop() + $("#artistsNav .active").position().top - w)
          , 0)
      )
]

app.directive "artistDetails", () ->
  restrict: "A"
  controller: ['$scope'
    ($scope) ->
  ]
  templateUrl: "/assets/templates/artist.html"

app.filter "minute", () ->
  (input) ->
    min = input / 60
    min.toFixed(2)

app.directive "mediaProgress", () ->
  restrict: "E"
  templateUrl: "/assets/templates/mediaprogress.html"
  controller: ['$scope', 'playerService'
    ($scope, playerService) ->
      $scope.spotTime = 0
      $scope.setPosition = (event) ->
        percent = event.offsetX / $scope.progressbar.width() * 100
        console.log percent
        time = ($scope.totalTime / 100) * percent
        $scope.audio[0].currentTime = time

  ]
  link: (scope, element, attrs) ->
    scope.spot = $(element.find(".media-current")[0])
    scope.progressbar = $(".media-progress")
    scope.circle = $(".media-current-spot")
    mediaElement = $('.audio')
    scope.updateProgress = () ->
      if !$(".media-progress").hasClass("dragging")
        value = scope.audio[0].currentTime
        if value == 0 || value == undefined
          pos = 0
        else
          pos = (value / scope.totalTime) * $(".media-bar").width()
          $(".media-current").css(left: pos)
        time = (scope.currentTime / 60).toFixed(2)
        $(".progress-tooltip").text(time)
        scope.$apply()

    mediaElement.bind("timeupdate", scope.updateProgress)

    scope.spot.draggable
      axis: "x"
      containment: $(".media-progress-container")
      start: (event, ui) ->
        $(".media-progress").addClass "dragging"
        return
      stop: (event, ui) ->
        $(".media-progress").removeClass "dragging"
        percent = scope.progressPercent()
        time = (scope.totalTime / 100) * percent
        scope.audio[0].currentTime = time
        return
      drag: (event, ui) ->
        percent = scope.progressPercent()
        time = (((scope.totalTime / 100) * percent) / 60).toFixed(2)
        $(".progress-tooltip").text(time)
        return

    scope.progressPercent = () ->
      percent = ((scope.circle.position().left - scope.progressbar.position().left) / scope.progressbar.width() ) * 100
      if percent > 100
        percent = 100
      percent

app.directive "audioPlayer", () ->
  restrict: "E"
  templateUrl: "/assets/templates/player.html"
  controller: ['$scope', '$location', 'playerService'
    ($scope, $location, playerService) ->
      $scope.playlist = playerService.getPlaylist()
      $scope.audio = null
      $scope.currentTrack = null
      $scope.repeat = false
      $scope.totalTime = 0
      $scope.currentTime = 0

      playerService.setAudioPlayer($scope)

      $scope.setAudio = (newAudio) ->
        $scope.audio = newAudio

      $scope.gotoQueue = ->
        $location.path("/queue")

      $scope.play = ->
        $scope.audio[0].play()

      $scope.playPause = ->
        if $scope.playing()
          $scope.audio[0].pause()
        else
          $scope.audio[0].play()

      $scope.playing = ->
        if $scope.audio[0].paused
          return false
        return true

      $scope.isReady = ->
        if $scope.playlist.length > 0
          return true
        false

      $scope.timeUpdate = ->
        $scope.currentTime = $scope.audio[0].currentTime
        $scope.$apply()

      $scope.durationChange = ->
        $scope.totalTime = $scope.audio[0].duration
        $scope.$apply()

      $scope.percent = ->
        if !$scope.isReady()
          return 0
        ($scope.currentTime / $scope.totalTime) * 100

      $scope.progress = ->
        {width: "#{$scope.percent()}%"}

      $scope.mediaCompleted = ->
        if $scope.currentTrack == $scope.playlist.length - 1
          $scope.setTrack(0)
          if $scope.repeat
            $scope.play()
        else
          $scope.setTrack($scope.currentTrack + 1)
          $scope.play()

      $scope.setTrack = (trackNumber) ->
        if trackNumber >= 0 && trackNumber < $scope.playlist.length
          track = $scope.playlist[trackNumber]
          $scope.currentTrack = trackNumber
          mediaSource =
            src: track.src
            type: track.type
          $scope.changeSource(mediaSource)

      $scope.getPlaylist = ->
        $scope.playlist

      $scope.prev = ->
        $scope.setTrack($scope.currentTrack - 1)
        $scope.play()

      $scope.next = ->
        $scope.setTrack($scope.currentTrack + 1)
        $scope.play()

      $scope.atFirst = ->
        if $scope.playlist.length == 0 || $scope.currentTrack == 0
          return true
        false

      $scope.atLast = ->
        if $scope.playlist.length == 0 || $scope.currentTrack == $scope.playlist.length - 1
          return true
        false

      $scope.getCurrentTrack = ->
        $scope.currentTrack
  ]
  controllerAs: 'playerCtrl'
  link: (scope, element, attrs, playerCtrl) ->
    mediaElement = $(element).find('.audio')
    scope.setAudio(mediaElement)

    mediaElement.bind("ended", scope.mediaCompleted)
    mediaElement[0].addEventListener("durationchange", scope.durationChange.bind(this), false)
    mediaElement.bind("timeupdate", scope.timeUpdate)

    scope.changeSource = (value) ->
      if value && value.src
        mediaElement.attr("src", value.src)
        mediaElement.attr("type", value.type)

app.directive 'autofocus', ['$timeout', ($timeout) ->
  restrict: 'A'
  link : ($scope, $element) ->
    $timeout () ->
      $element[0].focus()
]
