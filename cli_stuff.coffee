
  # cli_watch
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


          Promise.all(watches).then((results) ->

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

          Promise.all(watches).then (results) ->

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
