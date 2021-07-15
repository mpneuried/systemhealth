# Systemhealth

[![Build Status](https://secure.travis-ci.org/mpneuried/systemhealth.png?branch=master)](http://travis-ci.org/mpneuried/systemhealth)
[![Windows Tests](https://img.shields.io/appveyor/ci/mpneuried/systemhealth.svg?label=WindowsTest)](https://ci.appveyor.com/project/mpneuried/systemhealth)
[![Coveralls Coverage](https://img.shields.io/coveralls/mpneuried/systemhealth.svg)](https://coveralls.io/github/mpneuried/systemhealth)

[![Deps Status](https://david-dm.org/mpneuried/systemhealth.png)](https://david-dm.org/mpneuried/systemhealth)
[![npm version](https://badge.fury.io/js/systemhealth.png)](http://badge.fury.io/js/systemhealth)
[![npm downloads](https://img.shields.io/npm/dt/systemhealth.svg?maxAge=2592000)](https://nodei.co/npm/systemhealth/)

Node module to run simple custom checks for your machine or it's connections.

[![NPM](https://nodei.co/npm/systemhealth.png?downloads=true&stars=true)](https://nodei.co/npm/systemhealth)

## Install

```sh
  npm install systemhealth
```

## Initialize

```js
var Systemhealth = require("systemhealth");
var health = new Systemhealth({}, ["foo", "bar"], require("./mychecks"));
```

**Options**

- **interval** : _( `Number` optional: default = `60` )_ Check interval in seconds
- **intervalVariance** : _( `Number` optional: default = `0` )_ If you are using the same configuration for multiple servers you can define a variance that will add random seconds to the interval until this value.
- **failCount** : _( `Number` optional: default = `2` )_ Count of failed checks per check until "die". E.g. Mark server as dead until 2 failed checks of the sql connection.
- **successCount** : _( `Number` optional: default = `1` )_ Count of successful checks until the server resurrect.
- **failTimeout** : _( `Number` optional: default = `2000` )_ Internal check timeout to wait for answers of check tasks

## Methods

#### `.start()`

Start checking the health of the server and connections

**Return**

_( Systemhealth )_: The instance itself for chaining

#### `.stop()`

Stop checking interval

**Return**

_( Systemhealth )_: The instance itself for chaining

#### `.die()`

Mark the server as dead and stop the heartbeat.
This is called until one check failed for `option.failCount` times.

**Return**

_( Boolean )_: Successful died. If the health is already `dead` it'll return `false`

#### `.resurrect()`

Resurrect the server and restart the heartbeat.
This is called until all checks are successful for `option.successCount` times.

**Return**

_( Boolean )_: Successful died. If the health is already `dead` it'll return `false`

#### `.getState()`

return the last check state.

**Return**

_( Object )_: An object with the state of all checks.

Format: `{ "my-check-foo-name": [ {state}, {data} ] }`
_{state}_: Positive numbers represent the successful counts. Negative numbers represent the fail count.  
_{data}_: Optional data or error infos

## Events

#### `started`

Emitted on a successful start after the frist check.

#### `stopped`

Emitted on a check stop.

#### `died`

Emitted if the failCount has exceeded. So the server/machine is defined as dead.

#### `resurrected`

Emitted if the successCount has exceeded after the system was not dead. So the server/machine is defined as alive.

#### `checked`

Emitted after a check

**Arguments**

- **state** : _( `Object` )_ See method `.getState()` for teh description of the return

#### `failed`

A immediate event when a check fails.

**Arguments**

- **check** : _( `String` )_ The key of the failed check function
- **data** : _( `Any` )_ Optional data or error infos

## Example

```js
  var CHECKS = {
  	"memcached": function(){
  		var Memcached = require( 'memcached' );
  		var _client = new Memcached();
  		return function( cb ){
  			_client.version( function( err, version ){
  				if( err ){
  					cb( null, false, err ); // do not return a regular error. Just return false as second arg and optional info like the error object
  				}
  				cb( null, true, { _v: version } ); // just return true and optional information, that will be logged to redis metics
  			});
  		}
  	},
  	"sql": function(){
  		var _client = require( './my-sql-client42' );
  		return function( cb ){
  			_client.query( "SELECT 5", function( err, return ){
  				if( err ){
  					cb( null, false, err ); // do not return a regular error. Just return false as second arg and optional info like the error object
  				}
  				cb( null, true );
  			});
  		}
  	}
  }
  var Systemhealth = require( "systemhealth" );
  var health = new Systemhealth( { identifier: "my-server-name" }, [ "memcached", "sql" ], CHECKS );
```

## Properties

#### `alive`

If the service is alive this property will be `true`

**Return**

_( Boolean )_: If it's alive

## Testing

The tests are based on the [mocha.js](https://mochajs.org/) framework with [should.js](https://shouldjs.github.io/) as assertaion lib.
To start the test just call

```
	npm test
```

or

```
 grunt test
```

If you want to be more precice use the mocha cli

```
	mocha -R nyan -t 1337 test/main.js
```

### Docker-Tests

If you want to test your module against multiple node versions you can use the docker tests.

**Preparation**

```sh
	# make sure you installed all dependencies
	npm install
	# build the files
	grunt build
```

**Run**

To run the tests through the defined versions run the following command:

```
	dockertests/run.sh
```

## Release History

| Version |    Date    | Description                                                                                                                            |
| :-----: | :--------: | :------------------------------------------------------------------------------------------------------------------------------------- |
|  2.0.0  | 2021-07-15 | removed redis-heartbeat module. So the redis representation will no longer be available; updated docker tests to current node versions |
|  1.0.0  | 2018-05-07 | Updated deps., Updated redis-heartbeat without metrics to run on node 10 and coffee 2                                                  |
|  0.1.1  | 2017-08-11 | updated deps                                                                                                                           |
|  0.1.0  | 2016-10-12 | Optimized tests; Updated dependencies; Optimized Dev env.                                                                              |
|  0.0.5  | 2016-06-24 | Added `failed` event to get immediate infos on an failed check;                                                                        |
|  0.0.4  | 2016-05-19 | Updated dependencies; Updated dev env.; Removed generated code docs;                                                                   |
|  0.0.3  | 2016-01-07 | Updated dependencies; Optimized Readme                                                                                                 |
|  0.0.2  | 2015-03-11 | Small bugfix within redis connection listening                                                                                         |
|  0.0.1  | 2014-11-20 | Initial commit                                                                                                                         |

[![NPM](https://nodei.co/npm-dl/systemhealth.png?months=6)](https://nodei.co/npm/systemhealth/)

## Other projects

| Name                                                                              | Description                                                                                                                                                                                                                 |
| :-------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)               | Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.                                                                                                                      |
| [**node-cache**](https://github.com/tcs-de/nodecache)                             | Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.                                                                                                                                      |
| [**rsmq**](https://github.com/smrchy/rsmq)                                        | A really simple message queue based on Redis                                                                                                                                                                                |
| [**nsq-logger**](https://github.com/mpneuried/nsq-logger)                         | Nsq service to read messages from all topics listed within a list of nsqlookupd services.                                                                                                                                   |
| [**nsq-topics**](https://github.com/mpneuried/nsq-topics)                         | Nsq helper to poll a nsqlookupd service for all it's topics and mirror it locally.                                                                                                                                          |
| [**nsq-nodes**](https://github.com/mpneuried/nsq-nodes)                           | Nsq helper to poll a nsqlookupd service for all it's nodes and mirror it locally.                                                                                                                                           |
| [**nsq-watch**](https://github.com/mpneuried/nsq-watch)                           | Watch one or many topics for unprocessed messages.                                                                                                                                                                          |
| [**redis-sessions**](https://github.com/smrchy/redis-sessions)                    | An advanced session store for NodeJS and Redis                                                                                                                                                                              |
| [**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions) | A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id. |
| [**task-queue-worker**](https://github.com/smrchy/task-queue-worker)              | A powerful tool for background processing of tasks that are run by making standard http requests.                                                                                                                           |
| [**soyer**](https://github.com/mpneuried/soyer)                                   | Soyer is small lib for serverside use of Google Closure Templates with node.js.                                                                                                                                             |
| [**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)           | Compile Goggle Closure Templates ( SOY ) templates inclding the handling of XLIFF language files.                                                                                                                           |
| [**backlunr**](https://github.com/mpneuried/backlunr)                             | A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js                                                                                                                           |

## The MIT License (MIT)

Copyright © 2021 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
