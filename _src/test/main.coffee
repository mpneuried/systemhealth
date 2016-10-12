should = require('should')

Systemhealth = require( "../." )

CHECKS = require( "./checks" )

Health = null

describe "----- Systemhealth TESTS -----", ->

	describe 'Main Tests', ->

		# Implement tests cases here
		it "general", ( done )->
			Health = new Systemhealth( { interval: 3, identifier: "test" }, [ "checkFoo", "check42" ], CHECKS )
			this.timeout( 10000 )

			Health.on "checked", ->
				Health.getState().should.have.properties( "checkFoo", "check42" )
				Health.stop()
				done()
				return

			Health.start()
			return
		
		# Implement tests cases here
		it "error on start", ( done )->
			
			HealthErr = new Systemhealth( { interval: 3, identifier: "test" }, [ "checkFoo", "checkError" ], CHECKS )
			this.timeout( 10000 )

			HealthErr.on "checked", ->
				state = HealthErr.getState()
				state.should.have.properties( "checkFoo", "checkError" )
				should.exist( state[ "checkError" ][0] )
				state[ "checkError" ][0].should.lower(0)
				return
			
			HealthErr.on "died", ->
				HealthErr.stop()
				done()
				return

			HealthErr.start()
			return

	return
