Router.configure
	layoutTemplate: "layout"

@RegistrationSub = Meteor.subscribe "registrations"


Router.map ()->
	this.route "welcome",
			path: "/"
	this.route "practical", {}
	this.route "pricing", {}
	this.route "preregistration", {}

Template.navigation.style = (path)->
	style = if Router.current() and  Router.current().route.name is path then "active" else "inactive"
	return style

Template.preregister.events
	"change #amount": (event, template) ->
		amount = event.target.value
		console.log amount
	"click #addPreregistration": (event,template) ->
		event.preventDefault()
		Errors.clearAll()
		registration =
			remarks: template.find("#remarks").value
			tickets: []
		amounts = template.findAll "input.amount"
		_.each amounts, (amount)->
			ticket =
				amount: amount.value
				type: amount.getAttribute "name"
			if ticket.amount > 0
				registration.tickets.push ticket
		if registration.tickets.length is 0
			Errors.throw "Please specify at least one ticket amount", "registration"
			return
		Meteor.call "register",registration, (error)->
			if error
				Errors.throw error, "registration"
		return
