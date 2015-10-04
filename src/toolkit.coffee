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

  watch: (user_uuid, artifact_uuid) ->
    @request('post', "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}")

  unwatch: (user_uuid, artifact_uuid) ->
    @request('delete', "#{@pigeonUrl}/watch/#{artifact_uuid}/user/#{user_uuid}")


get_current_user_uuid = (wsapi) ->
  wsapi.get(url: 'user').then (result) -> result.ObjectUUID

init = (cli_args) ->

  username = cli_args.username ? 'joshuaclark@rallydev.com'
  password = cli_args.password ? 'Password'
  server = cli_args.server ? 'https://rally1.rallydev.com'

  Wsapi = require('./WsapiRequest.coffee')
  wsapi = new Wsapi
    server: server
    requestOptions:
      auth:
        user: username
        pass: password
        sendImmediately: false

  pigeon = new Pigeon wsapi

  getWatches = (user_uuid) ->
    pigeon.getWatches()


  watch = (user_uuid) ->

      query_keys = _(cli_args).keys().without('_').value()

      queries = for key in query_keys
        Query.where(key, 'contains', cli_args[key])

      wsapi_query_string = _.reduce(queries, (accum, query) -> accum.and query)?.toQueryString() ? ''

      query_string = fetch: _.uniq(['FormattedID', 'Name'].concat(query_keys)).join(',')
      if wsapi_query_string.length > 0
        query_string.query = wsapi_query_string

      console.log "Fetching artifacts with query string #{wsapi_query_string}..."

      wsapi.get(
        url: 'artifact'
        qs: query_string
      ).then((result) ->
          uuids = _.pluck(result.Results, '_refObjectUUID')

          console.log "Found #{result.TotalResultCount} artifacts."
          console.log "Watching #{uuids.length} artifacts..."

          watches = _.map uuids, (artifact_uuid) ->
            pigeon.watch(user_uuid, artifact_uuid).then (response) ->
              debugger


          Q.all(watches).then((results) ->

            successes = _.filter(results, {status: 200});
            alreadyWatched = _.filter(results, {status: 409});
            failed = _.filter results, (result) -> "#{result.status}".match /^[^2]/ and result.status isnt 409

            debugger

            console.log "Results: #{successes.length} watched. #{alreadyWatched.length} already watched. #{failed.length} failed."
          ).fail (error) ->
            debugger
      ).catch (error) ->
        debugger

  unwatch = (user_uuid) ->

      query_keys = _(cli_args).keys().without('_').value()

      queries = for key in query_keys
        Query.where(key, 'contains', cli_args[key])

      wsapi_query_string = _.reduce(queries, (accum, query) -> accum.and query)?.toQueryString() ? ''

      query_string = fetch: _.uniq(['FormattedID', 'Name'].concat(query_keys)).join(',')
      if wsapi_query_string.length > 0
        query_string.query = wsapi_query_string

      wsapi.get(
        url: 'artifact'
        qs: query_string
      ).then((result) ->
          uuids = _.pluck(result.Results, '_refObjectUUID')

          console.log "Found #{result.TotalResultCount} artifacts."
          console.log "Unwatching #{uuids.length} artifacts..."

          watches = _.map uuids, (artifact_uuid) -> pigeon.unwatch user_uuid, artifact_uuid

          Q.all(watches).then (results) ->

            successes = _.filter(results, {status: 200});
            alreadyUnwatched = _.filter(results, {status: 404});
            failed = _.filter results, (result) -> "#{result.status}".match(/^[^2]/) and result.status isnt 404

            debugger

            console.log "Results: #{successes.length} unwatched. #{alreadyUnwatched.length} were already not watched. #{failed.length} failed."

      ).catch (error) ->
        debugger

  user_id = get_current_user_uuid(wsapi).then (user_uuid) ->

    switch cli_args._[0]
      when 'getWatches' then getWatches user_uuid
      when 'watch' then watch user_uuid
      when 'unwatch' then unwatch user_uuid
      else
        debugger

  #   a_bunch_of_artifacts = result.Results
  #   uuid = a_bunch_of_artifacts[0]._refObjectUUID

  #   console.log "watching #{a_bunch_of_artifacts[0]._refObjectName} #{uuid}"

  #   pigeon.watch uuid

  #   console.log "sucess. found #{result.TotalResultCount} artifacts"
  # , (err) ->
  #   console.log 'you fail'
  # , (error) ->
  #   debugger

module.exports =
  init: init
