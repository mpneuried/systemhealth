# # systemhealth
# ### extends [NPM:MPBasic](https://cdn.rawgit.com/mpneuried/mpbaisc/master/_docs/index.coffee.html)
#
# ### Exports: *Class*
#
# Node module to run simple custom checks for your machine or it's connections. It will use redis-heartbeat to send the current state to redis.
# 

# **node modules**
os = require( "os" )
domain = require( "domain" )

# **npm modules**
_isArray = require( "lodash/isArray" )
async = require( "async" )

# **internal modules**
# The [Utils](./utils.coffee.html)
utils = require("./utils")

class SystemHealth extends require( "mpbasic" )()

	# ## defaults
	defaults: =>
		@extend true, super( arguments... ),

			# **interval** *Number* Check interval in seconds
			interval: 60
			# **interval** *Number* If you are using the same configuration for multiple servers you can define a variance that will add random seconds to the interval until this value.
			intervalVariance: 0
			# **failCount** *Number* Count of failed checks per check until "die". E.g. Mark server as dead until 2 failed checks of the sql connection.
			failCount: 2
			# **successCount** *Number* Count of successful checks until the server resurrect. 
			successCount: 1
			# **failTimeout** *Number* Internal check timeout to wait for answers of check tasks
			failTimeout: 2000

	###	
	## constructor 

	@param { Object } options See defaults
	@param { String[] } checks Array of checks to perform on every interval
	@param { Function{} } CHECKS Object of checks methods to perform. Every value should be a init function returning the check function.

	###
	constructor: ( options, checks, @CHECKS )->
		super( options )

		# get the checks for this servertype and check the content
		if not checks? or not _isArray( checks )
			@_handleError( true, "EEMPTYCHECKS" )
			return

		# init the checks
		@_init( checks )

		return

	###
	## _init
	
	`systemhealth._init( checks )`
	
	initialize the checks and define the internal variables
	
	@param { String[] } checks Array of checks to perform on every interval
	
	@return { Systemhealth } The instance itself for chaining 
	
	@api private
	###
	_init: ( checks )=>
		@alive = true
		@failed = {}
		@succeeded = {}
		@checkMetrics ={}

		# create the correct interval time
		if @config.intervalVariance >= 0
			@interval = ( @config.interval + utils.randRange( 0, @config.intervalVariance ) ) * 1000
		else
			@interval = @config.interval

		@info "health check interval: #{@interval/1000}s"
		@checks = {}
		for _name in checks
			if @CHECKS[ _name ]?
				@failed[ _name ] = 0
				@succeeded[ _name ] = 0
				@checks[ _name ] = @_checkTimeout(_name, @CHECKS[ _name ].apply( @ ) )
			else
				@warning "unknown check `#{_name}`"
		return @

	###
	## start
	
	`systemhealth.start()`
	
	Start checking the health of the server and connections
	
	@return { Systemhealth } The instance itself for chaining 
	
	@api public
	###
	start: =>
		@debug "start"
		@_check()
		@once "checked", =>
			@debug "start HB"
			@emit "started"
			return
		return @

	###
	## stop
	
	`systemhealth.stop()`
	
	Stop checking interval
	
	@return { Systemhealth } The instance itself for chaining 
	
	@api public
	###
	stop: =>
		@debug "stopped"
		clearTimeout( @timeout ) if @timeout
		@emit "stopped"
		return @

	###
	## die
	
	`systemhealth.die()`
	
	Mark the server as dead and stop the heartbeat.
	This is called until one check failed for `option.failCount` times.

	@return { Boolean } Successful died. If the health is already `dead` it'll return `false`
	
	@api public
	###
	die: =>
		return false if not @alive
		@alive = false
		@warning "die"
		@emit "died"
		return true

	###
	## resurrect
	
	`systemhealth.resurrect()`
	
	Resurrect the server and restart the heartbeat.
	This is called until all checks are successful for `option.successCount` times.
	
	@return { Boolean } Successful resurrection. If the health is already `alive` it'll return `false`
	
	@api public
	###
	resurrect: =>
		return false if @alive
		@alive = true
		@warning "resurrect"
		@emit "resurrected"
		return true

	###
	## getState
	
	`systemhealth.getState()`
	
	return the last check state.
	
	@return { Object } An object with the state of all checks.  
	Format: `{ "my-check-foo-name": [ {state}, {data} ] }`
	*{state}*: Positive numbers represent the successful counts. Negative numbers represent the fail count.  
	*{data}*: Optional data or error infos
	
	@api public
	###
	getState: =>
		@checkMetrics or null

	###
	## _recheck
	
	`systemhealth._recheck()`
	
	Call a check after a `options.interval` seconds

	@return { Systemhealth } The instance itself for chaining 
	
	@api private
	###
	_recheck: =>
		clearTimeout( @timeout ) if @timeout
		@timeout = setTimeout( @_check, @interval )
		return @

	###
	## _checkTimeout
	
	`systemhealth._checkTimeout( name, fn )`
	
	Wrap the check function to add a internal timeout 
	
	@param { String } name The check name 
	@param { Function } fn Check function 
	
	@return { Function } The wrapped check function
	
	@api private
	###
	_checkTimeout: ( name, fn )=>
		return ( cb )=>
			_timeout = =>
				cb( null, false, @_handleError( "ECHECKTIMEOUT", "ECHECKTIMEOUT", name: name ) )
				return
			fn( ( args... ) =>
				clearTimeout( _tmt )
				cb.apply( @, args )
				return
			)
			_tmt = setTimeout( _timeout, @config.failTimeout )
			return

	###
	## _check
	
	`systemhealth._check()`
	
	Main method to run all active check methods
	
	@api private
	###
	_check: =>
		# create the next `_check()` call immediately
		@_recheck()

		# create a domain to catch the async errors on internal timeout
		d = domain.create()
		d.on "error", ( _err )=>
			@warning "async-error", _err
			return

		# run all check inside a domain
		d.run =>
			async.parallel @checks, ( err, results )=>
				if err
					@fatal "A check function should never return a error", err
					return

				@debug "checked", results

				# define flags
				_fail = false
				_kill = false
				_resurrect = false

				# check every answer
				for _name, _res of results
					# dispatch result
					if _isArray( _res )
						[ success, data ] = _res
					else
						success = _res
						data = null

					# set the fails 
					if success
						@failed[ _name ] = 0
						@succeeded[ _name ]++
					else
						_fail = true
						@emit "failed", _name, data
						@warning "failed-#{_name}", data 
						@failed[ _name ]++
						@succeeded[ _name ] = 0

					# write the metric data.
					# Idx=0: Positive numbers represent the successful counts. Negative numbers represent the fail count.
					# Idx=1: Optional data or error infos
					@checkMetrics[ _name ] = [ if _fail then ( @failed[ _name ] * -1 ) else @succeeded[ _name ] ]
					if data?
						@checkMetrics[ _name ].push data

					# check for killing or resurrecting based on the configuration
					if @failed[ _name ] >= @config.failCount
						_kill = true
					else if @succeeded[ _name ] >= @config.successCount
						_resurrect = true

				@debug "state", @succeeded, @failed

				# stop heartbeat if the conditions of one check failed
				if @alive and _kill
					@die()
					return

				# restart the heartbeat if the conditions to resurrect are true
				if not @alive and not _kill and _resurrect
					@resurrect()
				
				@emit "checked", @checkMetrics
				return
			return
		return

	###
	## ERRORS
	
	`systemhealth.ERRORS()`
	
	Error detail mappings
	
	@return { Object } Return A Object of error details. Format: `"ERRORCODE":[ statusCode, "Error detail" ]` 
	
	@api private
	###
	ERRORS: =>
		@extend super( arguments... ),
			"EINVALIDCLINET": [ 500, "Please use a redis client instance for the `client` option." ]
			"EEMPTYIDENT": [ 500, "No server identifier defined." ]
			"EEMPTYCHECKS": [ 500, "For the type `#{@type}` no or an empty checklist has been found." ]
			"ECHECKTIMEOUT": [ 500, "The check `{{name}}` has been timed out." ]

#export this class
module.exports = SystemHealth
