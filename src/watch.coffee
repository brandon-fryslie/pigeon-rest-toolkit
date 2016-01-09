_ = require 'lodash'

module.exports =

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

        Promise.all(watches).then (results) =>
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

        Promise.all(watches).then (results) =>
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
