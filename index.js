require('coffee-script/register');
var toolkit = require('./src/toolkit');
var query = require('./lib/WsapiQuery');


module.exports = {
  init: toolkit.init,
  Query: query
};