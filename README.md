This toolkit allows you to script Rally's Pigeon REST Api to watch and unwatch artifacts, and to create webhooks rules (coming soon).

#### Usage

Install via npm and save to package.json

`npm install --save pigeon-rest-toolkit`

To use, require the module and instantiate it with your options:

```javascript

#!/usr/bin/env node

var toolkit = require('pigeon-rest-toolkit');

var pigeon = toolkit.init({
  server: 'http://rally.dev:8999',
  username: 'jimmy@rallydev.com',
  password: 'Password',
  debug: true
});

var Query = toolkit.Query;

pigeon.watch().then(function(results) {
  // Watched first 20 artifacts Jimmy has access to

  console.log(results.successful.length + ' succeeded');
  console.log(results.alreadyWatched.length + ' already watched');
  console.log(results.failed.length + ' failed');
});

// Get the watches for a user
pigeon.getWatches().then(function(results) {
  var watches = results.body;
  // console.log(watches);
});

pigeon.watch({
  username: 'bobby@rallydev.com'
}).then(function(results) {
  // Added Bobby as a watcher to Jimmy's first 20 artifacts

  console.log(results.successful.length + ' succeeded');
  console.log(results.alreadyWatched.length + ' already watched');
  console.log(results.failed.length + ' failed');
});

pigeon.watch({
  username: 'bobby@rallydev.com',
  query: Query.where('Name', 'contains', 'Story').and('ScheduleState', '<', 'Completed').toQueryString()
}).then(function(results) {
  // Added Bobby as a watcher to artifacts where Name contains 'Story' and 'ScheduleState' is less than 'Completed'

  console.log(results.successful.length + ' succeeded');
  console.log(results.alreadyWatched.length + ' already watched');
  console.log(results.failed.length + ' failed');
});

pigeon.unwatch({
  query: Query.where('Project.Name', '=', 'Sample Project').toQueryString(),
  pagesize: 200
}).then(function(results) {
  // Remove Jimmy as a watcher from all stories in that project

  console.log(results.successful.length + ' succeeded');
  console.log(results.alreadyUnwatched.length + ' already unwatched');
  console.log(results.failed.length + ' failed');
});

// Get all individual watch rules that match a query
pigeon.getWatchRules({
  query: Query.where('Project.Name', '=', 'Sample Project').toQueryString()
}).then(function(results) {
  // console.log('Results', results);
});

```
var pigeon