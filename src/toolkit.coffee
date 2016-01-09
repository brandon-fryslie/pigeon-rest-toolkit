require('es6-promise').polyfill()
rest = require 'unirest'
_ = require 'lodash'
require 'colors'
Ref = require '../lib/Ref'
Query = require '../lib/WsapiQuery'

Watch = require './watch'

class Pigeon

  constructor: (@wsapi, @DEBUG = false) ->

    @user_data_cache = {}

    @pigeonUrl = "#{@wsapi.server}/notifications/api/v1"

  _log: (args...) ->
    if @DEBUG
      console.log.apply @, ['debug: '.red].concat args

  request: (method, url) ->
    new Promise (resolve, reject) =>
      @wsapi.gimmeToken().then (token) =>
        rest[method](url).jar(true)
        .send()
        .end (response) ->
          resolve(response)

  get_uuid_for_user: (username) ->
    @_log "Fetching info for user #{username}"

    @wsapi.get(url: 'user/', qs: query: Query.where('UserName', '=', username).toQueryString()).then (result) =>
      result.Results?[0]._refObjectUUID

  _query_for_artifacts: (options = {}) ->
    wsapiOpts = url: 'artifact', fetch: 'UserName'

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

get_current_user_uuid = (wsapi) ->
  wsapi.get(url: 'user').then (result) -> result.ObjectUUID

init = (cli_args) ->

  if cli_args.debug
    console.log 'Debug output is on...'.red.bold

  username = cli_args.username ? ''
  password = cli_args.password ? ''
  server = cli_args.server ? 'https://rally1.rallydev.com'

  Wsapi = require('./WsapiRequest.coffee')
  wsapi = new Wsapi
    username: username
    password: password
    server: server
    debug: cli_args.debug

  pigeon = new Pigeon wsapi, cli_args.debug

  _.extend pigeon, Watch

module.exports =
  init: init
