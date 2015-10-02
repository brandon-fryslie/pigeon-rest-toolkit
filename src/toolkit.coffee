rest = require 'unirest'

SERVER = 'https://mistaf.testn.f4tech.com'


class pigeon

  constructor: ->
    @pigeonUrl = "#{SERVER}/notifications/"

  watch: (uuid) ->
    rest.post(@pigeonUrl).send()

Wsapi = require('./WsapiRequest.coffee')
wsapi = new Wsapi
  server: SERVER
  requestOptions:
    auth:
      user: 'joshuaclark@rallydev.com'
      pass: 'Password'
      sendImmediately: false


init = (cli_args) ->
  console.log 'Toolkit running!'

  wsapi.get(url: 'artifact').then (result) ->

    a_bunch_of_artifacts = result.Results

    console.log "sucess. found #{result.TotalResultCount} artifacts"
  , (err) ->
    console.log 'you fail'


module.exports =
  wsapi: wsapi
  init: init
