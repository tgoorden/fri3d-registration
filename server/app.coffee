Meteor.publish "registrations", ()-> Registrations.find {},{fields:{remarks:0}}

Meteor.methods
	"register": (registration)->
		if !Meteor.user()
			throw new Meteor.Error 403,"You have to be logged in to register"
		launch = moment.utc(Meteor.public.settings.launch)
		now = moment.utc()
		if now.isBefore(launch)
			throw new Meteor.Error 500, "We haven't launched yet. Good effort, but no."
		allowed_types = _.pluck tickettypes, "type"
		_.each registration.tickets, (ticket)->
			if ticket.amount < 1 or ticket.amount > 10
				throw new Meteor.Error 500, "Minimum 1, maximum 10 tickets per type"
			tt = _.findWhere tickettypes, {type: ticket.type}
			if !tt
				throw new Meteor.Error 500, "Unknown ticket type: #{ticket.type}"
			else
				ticket.owner = Meteor.userId()
				ticket.subtotal = tt.cost * ticket.amount
				ticket.remarks = registration.remarks if registration.remarks
				ticket.created = new Date()
				Registrations.insert ticket
		return


Accounts.validateNewUser (user)->
	console.log "Validating user"
	console.log EJSON.stringify user
	if !user.emails || user.emails.length is 0
		console.log "Email address missing"
		throw new Meteor.Error 500, "An email address is required to create a user"
	# Email validation:
	address = user.emails[0].address
	url = "https://api.mailgun.net/v2/address/validate"
	pubkey = Meteor.settings.mailgun_pubkey
	check = HTTP.get url,{auth:"api:#{pubkey}",params:{"address":address}}
	if check.data && !check.data.is_valid
		console.log EJSON.stringify check.data
		throw new Meteor.Error 500, "Email address did not pass validation"
	return true
