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
				amount: parseInt amount.value
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

Template.jumbotron.statistics = ()->
		statistics =
			total: 256
			preregistrations: 0
		_.each Registrations.find({}).fetch(), (registration)->
			statistics.preregistrations += registration.amount
		statistics.remaining = statistics.total - statistics.preregistrations
		if statistics.remaining < 1
			statistics.soldout = true
			statistics.style = "soldout"
		else
			statistics.style = "open"
		return statistics

# The countdown timer:
countDown = ()->
	launch = moment.utc(Meteor.settings.public.launch)
	now = moment.utc()
	Session.set "countdown", launch.fromNow()
	if now.isAfter(launch)
		Session.set "launched", true
		id = Session.get "countdown_id"
		if id
			Meteor.clearInterval id

Meteor.startup ()->
	Session.set "launched", false
	countdown_id = Meteor.setInterval countDown, 1000

Template.preregister.open = ()-> Session.get "launched"

Template.preregister.countdown = ()-> Session.get "countdown"

# (Pre-)registration listings:

Template.registrations.hasRegistrations = ()->
		Registrations.find({owner:Meteor.userId()}).count() > 0


Template.registrations.list = ()-> Registrations.find {owner:Meteor.userId()}

Template.registrations.total = ()->
		total =
			amount: 0
			cost: 0
		_.each Registrations.find({owner:Meteor.userId()}).fetch(), (registration)->
			total.amount += registration.amount
			total.cost += registration.subtotal
		return total

Template.registration.events
	"click .remove": (event,template)->
		event.preventDefault()
		confirmed = confirm "Are you sure you want to delete this preregistration?"
		if confirmed
			Registrations.remove {_id:this._id}
		return
