# create a simulated client
_createClient = ( timeout=300, success=true )->
	_ret =
		ping: ( cb )->
			setTimeout( ->
				if success
					cb( null, "pong" )
				else
					_err = new Error()
					_err.name = "simulated-error-ping"
					cb( _err )
				return
			, timeout )
			return
		query: ( statement, cb )->
			setTimeout( ->
				if success
					cb( null, [ { id: 42, name: "Bar", statement: statement } ] )
				else
					_err = new Error()
					_err.name = "simulated-error-query"
					cb( _err )
				return
			, timeout )
			return
	return _ret
	
module.exports =
	"checkFoo": ->
		# simulated checks
		_client = _createClient()

		return ( cb )->
			_client.ping ( err, pong )->
				if err
					cb( null, false, err )
					return
				cb( null, true )
				return
			return

	"checkBar": ->
		_client = _createClient( 3000 )
		return ( cb )->
			_client.ping ( err, pong )->
				if err
					cb( null, false, err )
					return
				cb( null, true )
				return
			return

	"check42": ->
		_client = _createClient()
		return ( cb )->
			_client.query "SELECT 5", ( err, results )->
				if err
					cb( null, false, err )
					return
				if not results?.length
					cb( null, false )
					return
				cb( null, true )
				return
			return
