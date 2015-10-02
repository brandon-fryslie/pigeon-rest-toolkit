Q = require 'q'
request = require 'request'
_ = require 'lodash'

API_VERSION = '2.x'

class Wsapi

  defaultRequestOptions:
    json: true
    gzip: true
    headers:
      'X-RallyIntegrationLibrary': 'Pigeon Rest Toolkit v0.0.1'
      'X-RallyIntegrationName': 'Pigeon Rest Toolkit'
      'X-RallyIntegrationVendor': 'Rally Software, Inc.'
      'X-RallyIntegrationVersion': '0.0.1'

  constructor: (options = {}) ->
    @server = options.server
    @wsapiUrl = "#{@server}/slm/webservice/v#{API_VERSION}"
    @httpRequest = request.defaults(_.merge({jar: true}, options.requestOptions, @defaultRequestOptions))

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
        deferred.reject msg: 'Could not find token in body', body: body

      @_token = token
      deferred.resolve token

    deferred.promise

  doSecuredRequest: (method, options) ->
    @gimmeToken().then((token) =>
      @doRequest(method, options)
    )

  doRequest: (method, options) ->
    deferred = Q.defer()

    requestOpts = _.extend {}, options, url: "#{@wsapiUrl}/#{options.url}"

    @httpRequest[method] requestOpts, (error, response, body) ->
      if error
        deferred.reject error
      else if !response
        deferred.reject("Unable to connect to server: #{self.wsapiUrl}");
      else if !body or !_.isObject(body)
        deferred.reject("#{options.url}: #{response.statusCode}! body=#{body}");
      else
        result = _.values(body)[0]
        if result.Errors.length
          deferred.reject result.Errors
        else
          deferred.resolve result

    deferred.promise

  get: (options) -> @doSecuredRequest 'get', options
  post: (options) -> @doSecuredRequest 'post', options
  put: (options) -> @doSecuredRequest 'put', options
  del: (options) -> @doSecuredRequest 'del', options

module.exports = Wsapi