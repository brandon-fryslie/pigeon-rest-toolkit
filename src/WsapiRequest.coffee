Q = require 'q'
request = require 'request'
_ = require 'lodash'

API_VERSION = '2.x'

class Wsapi

  defaultRequestOptions:
    jar: true
    json: true
    gzip: true
    headers:
      'X-RallyIntegrationLibrary': 'Pigeon Rest Toolkit v0.0.1'
      'X-RallyIntegrationName': 'Pigeon Rest Toolkit'
      'X-RallyIntegrationVendor': 'Rally Software, Inc.'
      'X-RallyIntegrationVersion': '0.0.1'

  constructor: (options = {}) ->
    @server = options.server
    @username = options.username
    @password = options.password
    @wsapiUrl = "#{@server}/slm/webservice/v#{API_VERSION}"
    @DEBUG = options.debug

    @httpRequest = request.defaults(_.merge({auth: {user: options.username, pass: options.password, sendImmediately: false}}, @defaultRequestOptions))

  _log: (args...) ->
    if @DEBUG
      console.log.apply @, ['debug: '.red].concat args

  gimmeToken: ->
    deferred = Q.defer()

    if @_token
      deferred.resolve(@_token)
      return deferred.promise

    @httpRequest.get "#{@wsapiUrl}/security/authorize", {}, (err, response, body) =>
      if err
        deferred.reject err
        return deferred.promise

      token = body.OperationResult?.SecurityToken

      if !token? or token.length < 10
        @_log 'Invalid username / password!'
        deferred.reject 'Invalid username / password!'

      @_log "Got new token: #{token}"

      @_token = token
      deferred.resolve token

    deferred.promise

  doSecuredRequest: (method, options) ->
    @gimmeToken().then((token) =>
      @doRequest(method, _.merge({qs: key: token}, options))
    )

  doRequest: (method, options) ->
    deferred = Q.defer()

    url = "#{@wsapiUrl}/#{options.url}"

    @_log "WsapiRequest #{method} #{url} #{JSON.stringify(options)}"

    requestOpts = _.extend {}, options, url: url

    @httpRequest[method] requestOpts, (error, response, body) =>
      if error
        @_log "Request error: ", error
        deferred.reject error
      else if !response
        @_log "Unable to connect to server: #{@wsapiUrl}"
        deferred.reject("Unable to connect to server: #{@wsapiUrl}");
      else if !body or !_.isObject(body)
        @_log "Request error: #{options.url}: #{response.statusCode}! body=#{body}"
        deferred.reject("#{options.url}: #{response.statusCode}! body=#{body}");
      else
        result = _.values(body)[0]
        if result.Errors.length
          @_log "Request error: ", result.Errors
          deferred.reject result.Errors
        else
          @_log "WsapiRequest Response: Success! TotalResultCount: #{result.TotalResultCount}"
          deferred.resolve result

    deferred.promise

  get: (options) -> @doSecuredRequest 'get', options
  post: (options) -> @doSecuredRequest 'post', options
  put: (options) -> @doSecuredRequest 'put', options
  del: (options) -> @doSecuredRequest 'del', options

module.exports = Wsapi