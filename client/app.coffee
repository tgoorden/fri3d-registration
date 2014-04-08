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
	style = if Router.current().route.name is path then "active" else "inactive"
	return style

Template.preregistration.events
	"change #amount": (event, template) ->
		amount = event.target.value
		console.log amount
	"click #addPreregistration": (event,template) ->
		event.preventDefault()
		console.log "Preregistration clicked"
		ticketType = template.find("input[name='ticketType']:checked").value
		amount = template.find("input[name='amount']").value
		console.log "Ticket type #{ticketType}"
		return
