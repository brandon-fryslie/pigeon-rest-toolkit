rest = require 'unirest'
_ = require 'lodash'
Q = require 'q'
require 'colors'


Ref = require '../lib/Ref'
Query = require '../lib/WsapiQuery'

class Pigeon

  constructor: (@wsapi, @DEBUG = false) ->

    @user_data_cache = {}

    @pigeonUrl = "#{@wsapi.server}/notifications/api/v1"

  _log: (args...) ->
    if @DEBUG
      console.log.apply @, ['debug: '.red].concat args

  request: (method, url) ->
    deferred = Q.defer()

    @wsapi.gimmeToken().then (token) =>
      rest[method](url).jar(true)
      .send()
      .end (response) ->
        deferred.resolve(response)

    deferred.promise

  getWatches: (username = @wsapi.username) ->
    @_log "getWatches for user #{username}"

    @get_uuid_for_user(username).then (user_uuid) =>
      @request('get', "#{@pigeonUrl}/watch/user/#{user_uuid}")

  getWatchRules: (options = {}) ->
    watch_user = options.username ? @wsapi.username

    @get_uuid_for_user(watch_user).then (user_uuid) =>

      @_query_for_artifacts(options).then (result) ->

        uuids = _.pluck(result.Results, '_refObjectUUID')

        @_log "Getting watch rules for user #{watch_user}"

        Q.all _.map uuids, (artifact_uuid) ->
          @_getWatchRule user_uuid, artifact_uuid

  _getWatchRule: (user_uuid, artifact_uuid) ->
    @request('get', "#{@pigeonUrl}/watch/user/#{artifact_uuid}/#{user_uuid}")

  get_uuid_for_user: (username) ->
    @_log "Fetching info for user #{username}"

    @wsapi.get(url: 'user/', qs: query: Query.where('UserName', '=', username).toQueryString()).then (result) =>
      result.Results?[0]._refObjectUUID

  _query_for_artifacts: (options = {}) ->
    wsapiOpts = {url: 'artifact', fetch: 'UserName'}

    if options.query? or options.pagesize?
      wsapiOpts.qs = {}

    if options.query?
      query = options.query
      @_log "Fetching artifacts with query string #{query}..."
      wsapiOpts.qs.query = query

    if options.pagesize?
      pagesize = options.pagesize
      @_log "Using pagesize #{pagesize}..."
      wsapiOpts.qs.pagesize = pagesize

    @wsapi.get(wsapiOpts)

  # options can optionaly contain a username or a wsapi query
  watch: (options = {}) ->
    watch_user = options.username ? @wsapi.username

    @get_uuid_for_user(watch_user).then (user_uuid) =>

      @_query_for_artifacts(options).then (result) =>
        uuids = _.pluck(result.Results, '_refObjectUUID')

        @_log "Found #{result.TotalResultCount} artifacts."
        @_log "Watching #{uuids.length} artifacts for #{watch_user}..."

        watches = _.map uuids, (artifact_uuid) =>
          @_watch(user_uuid, artifact_uuid)

        Q.all(watches).then (results) =>
          results =
            successful: _.filter results, status: 200
            alreadyWatched: _.filter results, status: 409
            failed: _.filter results, (result) -> result.status isnt 200 and result.status isnt 409

          @_log "Watch results: successful #{results.successful.length}, already watched #{results.alreadyWatched.length}, failed #{results.failed.length}"

          results

  # options can optionaly contain a username or a wsapi query
  unwatch: (options = {}) ->
    watch_user = options.username ? @wsapi.username

    @get_uuid_for_user(watch_user).then (user_uuid) =>

      @_query_for_artifacts(options).then (result) =>
        uuids = _.pluck(result.Results, '_refObjectUUID')

        @_log "Found #{result.TotalResultCount} artifacts."
        @_log "Unwatching #{uuids.length} artifacts..."

        watches = _.map uuids, (artifact_uuid) =>
          @_unwatch(user_uuid, artifact_uuid)

        Q.all(watches).then (results) =>
          results =
            successful: _.filter results, status: 200
            alreadyUnwatched: _.filter results, status: 404
            failed: _.filter results, (result) -> result.status isnt 200 and result.status isnt 404

          @_log "Unwatch results: successful #{results.successful.length}, already unwatched #{results.alreadyUnwatched.length}, failed #{results.failed.length}"

          results

  # Internal methods operate only on UUIDs
  _watch: (user_uuid, artifact_uuid) ->
    url = "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}"
    # @_log "pigeon POST #{url}"
    @request 'post', url

  # Internal methods operate only on UUIDs
  _unwatch: (user_uuid, artifact_uuid) ->
    @request('delete', "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}")

get_current_user_uuid = (wsapi) ->
  wsapi.get(url: 'user').then (result) -> result.ObjectUUID

init = (cli_args) ->

  if cli_args.debug
    console.log 'Debug output is on...'.red.bold

  username = cli_args.username ? 'joshuaclark@rallydev.com'
  password = cli_args.password ? 'Password'
  server = cli_args.server ? 'https://rally1.rallydev.com'

  Wsapi = require('./WsapiRequest.coffee')
  wsapi = new Wsapi
    username: username
    password: password
    server: server
    debug: cli_args.debug

  new Pigeon wsapi, cli_args.debug

module.exports =
  init: init
