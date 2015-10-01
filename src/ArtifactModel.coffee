Model = require 'backbone-model'

module.exports = class ArtifactModel extends Model

  urlRoot: 'https://mistaf.testn.f4tech.com/slm/webservice/v2.x/artifact'

  parse: (data) ->
    debugger