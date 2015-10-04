rest = require 'unirest'
_ = require 'lodash'
Q = require 'q'


Ref = require '../lib/Ref'
Query = require '../lib/WsapiQuery'

class Pigeon

  constructor: (@wsapi) ->
    @pigeonUrl = "#{@wsapi.server}/notifications/api/v1"

  request: (method, url) ->
    deferred = Q.defer()

    @wsapi.gimmeToken().then (token) =>
      rest[method](url).jar(true)
      .send()
      .end (response) ->
        deferred.resolve(response)

    deferred.promise

  getWatches: (user_uuid) ->
    @request('get', "#{@pigeonUrl}/watch/user/#{user_uuid}").then (response) ->
      debugger

  getWatchRule: (artifact_uuid) ->

  get_uuid_for_user: (username) ->
    @wsapi.get(url: 'user/', qs: query: Query.where('UserName', '=', username).toQueryString()).then (result) ->
      result.Results?[0]._refObjectUUID

  # options can optionaly contain a username or a wsapi query
  watch: (options = {}) ->
    wsapiOpts = {url: 'artifact', fetch: 'UserName'}

    if options.query?
      query = options.query
      console.log "Fetching artifacts with query string #{query}..."
      wsapiOpts.qs = query: query

    watch_user = options.username ? @wsapi.username

    @get_uuid_for_user(watch_user).then (user_uuid) =>

      @wsapi.get(wsapiOpts).then((result) =>
          uuids = _.pluck(result.Results, '_refObjectUUID')

          console.log "Found #{result.TotalResultCount} artifacts."
          console.log "Watching #{uuids.length} artifacts for #{watch_user}..."

          watches = _.map uuids, (artifact_uuid) =>
            @_watch(user_uuid, artifact_uuid)

          Q.all(watches)
      )

    # options can optionaly contain a username or a wsapi query
  unwatch: (options = {}) ->
    wsapiOpts = {url: 'artifact', fetch: 'UserName'}

    if options.query?
      query = options.query
      console.log "Fetching artifacts with query string #{query}..."
      wsapiOpts.qs = query: query

    @get_uuid_for_user(options.username ? @wsapi.username).then (user_uuid) =>

      @wsapi.get(wsapiOpts).then (result) =>
        uuids = _.pluck(result.Results, '_refObjectUUID')

        console.log "Found #{result.TotalResultCount} artifacts."
        console.log "Unwatching #{uuids.length} artifacts..."

        watches = _.map uuids, (artifact_uuid) =>
          @_unwatch(user_uuid, artifact_uuid)

        Q.all(watches)

  # Internal methods operate only on UUIDs
  _watch: (user_uuid, artifact_uuid) ->
    @request('post', "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}")

  # Internal methods operate only on UUIDs
  _unwatch: (user_uuid, artifact_uuid) ->
    @request('delete', "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}")

get_current_user_uuid = (wsapi) ->
  wsapi.get(url: 'user').then (result) -> result.ObjectUUID

init = (cli_args) ->

  username = cli_args.username ? 'joshuaclark@rallydev.com'
  password = cli_args.password ? 'Password'
  server = cli_args.server ? 'https://rally1.rallydev.com'

  Wsapi = require('./WsapiRequest.coffee')
  wsapi = new Wsapi
    username: username
    password: password
    server: server

  new Pigeon wsapi

module.exports =
  init: init
