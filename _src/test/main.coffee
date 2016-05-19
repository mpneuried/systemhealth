should = require('should')

Systemhealth = require( "../." )

CHECKS = require( "./checks" )

Health = null

describe "----- Systemhealth TESTS -----", ->

	before ( done )->
		Health = new Systemhealth( { interval: 3, identifier: "test" }, [ "checkFoo", "check42" ], CHECKS )
		done()
		return

	after ( done )->
		done()
		return

	describe 'Main Tests', ->

		# Implement tests cases here
		it "general", ( done )->
			this.timeout( 10000 )

			Health.on "checked", ->
				Health.getState().should.have.properties( "checkFoo", "check42" )
				done()
				return

			Health.start()
			return

	return
