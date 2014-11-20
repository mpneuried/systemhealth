Systemhealth
============

[![Build Status](https://secure.travis-ci.org/mpneuried/systemhealth.png?branch=master)](http://travis-ci.org/mpneuried/systemhealth)
[![Build Status](https://david-dm.org/mpneuried/systemhealth.png)](https://david-dm.org/mpneuried/systemhealth)
[![NPM version](https://badge.fury.io/js/systemhealth.png)](http://badge.fury.io/js/systemhealth)

Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.

*Written in coffee-script*

**INFO: all examples are written in coffee-script**

## Install

```sh
  npm install systemhealth
```

## Initialize

```js
  var Systemhealth = require( "systemhealth" );
  var health = new Systemhealth( { identifier: "my-server-name" }, [ "foo", "bar" ], require( "./mychecks" ) )
```

**Options** 

- **identifier** : *( `String|Function` required )* The heartbeat identifier content as string or function. Passed directly to `redis-heartbeat`
- **name** : *( `String` optional: default = `os.hostname()` )* A server type name. Default is the host name. Passed directly to `redis-heartbeat

- **interval** : *( `Number` optional: default = `60` )* Check interval in seconds
- **intervalVariance** : *( `Number` optional: default = `0` )* If you are using the same configuration for multiple servers you can define a variance that will add random seconds to the interval until this value.
- **failCount** : *( `Number` optional: default = `2` )* Count of failed checks per check until "die". E.g. Mark server as dead until 2 failed checks of the sql connection.
- **successCount** : *( `Number` optional: default = `1` )* Count of successful checks until the server resurrect. 
- **failTimeout** : *( `Number` optional: default = `2000` )* Internal check timeout to wait for answers of check tasks

- **host** : *( `String` optional: default = `localhost` )* Redis host name. Passed directly to `redis-heartbeat`
- **port** : *( `Number` optional: default = `6379` )* Redis port. Passed directly to `redis-heartbeat`
- **options** : *( `Object` optional: default = `{}` )* Redis options. Passed directly to `redis-heartbeat`
- **client** : *( `RedicClient` optional: default = `null` )* It also possible to pass in a already existing redis client instance. In this .case the options `host`, `port` and `options` ar ignored. Passed directly to `redis-heartbeat`
- **redisprefix** : *( `String` optional: default = `{}` )* A general redis key prefix. Passed directly to `redis-heartbeat`
- **heartbeatOptions** : *( `Object` optional: default = `{}` )* Optional `redis-heartbeat` options. [Details](https://github.com/mpneuried/redis-heartbeat#initialize)

## Methods

#### `.start()`

Start checking the health of the server and connections

**Return**

*( Systemhealth )*: The instance itself for chaining 

#### `.stop()`

Stop checking interval

**Return**

*( Systemhealth )*: The instance itself for chaining 

#### `.die()`

Mark the server as dead and stop the heartbeat.
	This is called until one check failed for `option.failCount` times.

**Return**

*( Boolean )*: Successful died. If the health is already `dead` it'll return `false`

#### `.resurrect()`

Resurrect the server and restart the heartbeat.
This is called until all checks are successful for `option.successCount` times.

**Return**

*( Boolean )*: Successful died. If the health is already `dead` it'll return `false`

#### `.getState()`

return the last check state.

**Return**

*( Object )*: An object with the state of all checks. 

Format: `{ "my-check-foo-name": [ {state}, {data} ] }`
*{state}*: Positive numbers represent the successful counts. Negative numbers represent the fail count.  
*{data}*: Optional data or error infos

## Events

#### `started`

Emitted on a successfull start of the heartbeat after the frist check.

#### `stopped`

Emitted on a check stop.

#### `died`

Emitted on heartbeat stop. So the server/machine is defined as dead.

#### `resurrected`

Emitted on restart of heartbeat. So the server/machine is defined as alive.

#### `checked`

Emitted after a check

**Arguments** 

- **state** : *( `Object` )* See method `.getState()` for teh description of the return

## Example

```js
  var CHECKS = {
  	"memcached": function(){
  		var Memcached = require( 'memcached' );
  		var _client = new Memcached();
  		return function( cb ){
  			_client.version( function( err, version ){
  				if( err ){
  					cb( null, false, err ); // do not return a regular error. Just return false as second arg and optinal info like the error object
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
  					cb( null, false, err ); // do not return a regular error. Just return false as second arg and optinal info like the error object
  				}
  				cb( null, true );
  			});
  		}
  	}
  }
  var Systemhealth = require( "systemhealth" );
  var health = new Systemhealth( { identifier: "my-server-name" }, [ "memcached", "sql" ], CHECKS );
```

## Release History

|Version|Date|Description|
|:--:|:--:|:--|
|0.0.1|2014-11-20|Initial commit|

## Other projects

|Name|Description|
|:--|:--|
|[**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)|Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.|
|[**node-cache**](https://github.com/tcs-de/nodecache)|Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on Redis|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions).
With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for serverside use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates inclding the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|

## The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
