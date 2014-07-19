@tickettypes =[]

Meteor.startup ()->
	_.each [3..8], (bits)->
		tickettypes.push
			type: "#{bits}bit"
			cost: Math.pow 2,bits
	tickettypes.push
		type: "6bitvolunteer"
		cost: 32
	tickettypes.push
		type: "7bitvolunteer"
		cost: 96
