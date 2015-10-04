


This toolkit allows you to script Rally's Pigeon REST Api to watch and unwatch artifacts, and to create webhooks rules (coming soon).

#### Usage

Install via npm and save to package.json

`npm install --save pigeon-rest-toolkit`

To use, require the module and instantiate it with your options:

```javascript

var toolkit = require('pigeon-rest-toolkit')
var _ = require 'lodash'

var Pigeon = toolkit.Pigeon
var Query = toolkit.WsapiQuery

var pigeon = new Pigeon({
  server: 'rally1.rallydev.com',
  username: 'jimmy@rallydev.com',
  password: 'very_secure_password'
});

pigeon.watch().then(function(results) {
  // Watched Jimmy's first 20 artifacts
});

pigeon.watch({
  username: 'bobby@rallydev.com'
}).then(function(results) {
  // Added Bobby as a watcher to Jimmy's first 20 artifacts

  var successfulResults = _.filter(results, {status: 200});
  var alreadyWatched = _.filter(results, {status: 409});
  var failed = _.filter(results, function(result) {
    return result.status !== 200 || result.status !== 409;
  });
});

pigeon.watch({
  username: 'bobby@rallydev.com'
  query: Query.where('Name', 'contains', 'Iteration Status').and('ScheduleState', '<', 'Completed')
}).then(function(results) {
  // Added Bobby as a watcher to artifacts where Name contains 'Iteration Status' and 'ScheduleState' is less than 'Completed'
});

pigeon.unwatch({
  username: 'hans@rallydev.com'
  query: Query.where('Project.Name', '=', 'AdminProject')
}).then(function(results) {
  // Remove Hans as a watcher from all stories in that project
});

pigeon.unwatch({
  username: 'hans@rallydev.com'
  query: Query.where('Project.Name', '=', 'AdminProject')
}).then(function(results) {
  // Remove Hans as a watcher from all stories in that project
});


```
var pigeon