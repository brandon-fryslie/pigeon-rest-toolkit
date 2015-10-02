rest = require 'unirest'

# SERVER = 'https://mistaf.testn.f4tech.com'
SERVER = 'https://rally1.rallydev.com'


class Pigeon

  constructor: (@wsapi) ->
    @pigeonUrl = "#{SERVER}/notifications/api/v1"

  getWatches: (userUUID) ->
    # @wsapi.gimmeToken().then (token) =>
      rest
      .get("#{@pigeonUrl}/watch/user/#{userUUID}")
      .jar(true)
      .send()
      .end (response) ->
        debugger

  # watch: (uuid) ->
  #   @wsapi.gimmeToken().then((token) =>
  #     watchUrl = "#{@pigeonUrl}/watch/#{uuid}"
  #     console.log 'sending request...', watchUrl
  #     # CookieJar = rest.jar()
  #     # CookieJar.add("key=#{token}", '/')
  #     rest
  #     .post(watchUrl)
  #     .header('Cookie', "ZSESSIONID=#{token};")
  #     .send()
  #     .end (response) =>

  #       debugger
  #   ).fail((error) ->
  #     debugger
  #   )

Wsapi = require('./WsapiRequest.coffee')
wsapi = new Wsapi
  server: SERVER
  requestOptions:
    auth:
      user: 'joshuaclark@rallydev.com'
      pass: 'Password'
      sendImmediately: false

init = (cli_args) ->

  pigeon = new Pigeon wsapi

  pigeon.getWatches 'b4054c42-d62b-42fc-9956-bb1473f31221'


  # wsapi.get(url: 'artifact').then (result) ->

  #   a_bunch_of_artifacts = result.Results
  #   uuid = a_bunch_of_artifacts[0]._refObjectUUID

  #   console.log "watching #{a_bunch_of_artifacts[0]._refObjectName} #{uuid}"

  #   pigeon.watch uuid

  #   console.log "sucess. found #{result.TotalResultCount} artifacts"
  # , (err) ->
  #   console.log 'you fail'


module.exports =
  wsapi: wsapi
  init: init
