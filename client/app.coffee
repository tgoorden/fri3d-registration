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

Template.preregistration.events
	"change #amount": (event, template) ->
		amount = event.target.value
		console.log amount
	"click #addPreregistration": (event,template) ->
		event.preventDefault()
		Errors.clearAll()
		registration = {}
		ticketRadio = template.find("#registrationForm input[name=ticketType]:checked")
		if !ticketRadio
			Errors.throw "Please choose a ticket type", "registration"
			return
		registration.ticketType = ticketRadio.value
		amount = template.find("#amount").value
		if !amount or amount < 1 or amount > 10
			Errors.throw "Please choose a valid number of tickets", "registration"
			return
		registration.amount = amount
		Meteor.call "register",registration, (error)->
			if error
				Errors.throw error, "registration"
		return
