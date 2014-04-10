@tickettypes =[]

Meteor.startup ()->
	_.each [3..8], (bits)->
		tickettypes.push
			type: "#{bits}bit"
			cost: Math.pow 2,bits
	
