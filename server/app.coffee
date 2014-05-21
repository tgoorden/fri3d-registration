Meteor.publish "registrations", ()-> Registrations.find {},{fields:{remarks:0}}

Meteor.methods
	"register": (registration)->
		if !Meteor.user()
			throw new Meteor.Error 403,"You have to be logged in to register"
		launch = moment.utc(Meteor.settings.public.launch)
		now = moment.utc()
		if now.isBefore(launch)
			throw new Meteor.Error 500, "We haven't launched yet. Good effort, but no."
		total = 0
		allowed_types = _.pluck tickettypes, "type"
		_.each registration.tickets, (ticket)->
			if ticket.amount < 1 or ticket.amount > 10
				throw new Meteor.Error 500, "Minimum 1, maximum 10 tickets per type"
			total = total + ticket.amount
			tt = _.findWhere tickettypes, {type: ticket.type}
			if !tt
				throw new Meteor.Error 500, "Unknown ticket type: #{ticket.type}"
			else
				ticket.owner = Meteor.userId()
				ticket.subtotal = tt.cost * ticket.amount
				ticket.remarks = registration.remarks if registration.remarks
				ticket.created = new Date()
				Registrations.insert ticket
		email =
			from: "Fri3d Camp Support <general@support.fri3d.be>"
			to: Meteor.user().emails[0].address
			subject: "You have successfully registered for the Fri3d Camp!"
			text: "Dear hacker,\n\n

				You have successfully pre-registered #{total} tickets for Fri3d Camp! Thanks for your interest in participating!
\n\n
				We'll handle ticket sales FIFO-style (once we have our VZW up and running), you will receive an e-mail when it's your turn.
\n\n
				In the mean time, please join the wiki at http://fri3d.be (the secret is 'stoofvlees') and contribute, as this camp is organized as a wiki and your input is very welcome!
\n\n
				Also check out the mailing list at https://groups.google.com/forum/#!forum/belgian-summer-hackercamp-2014 where we discuss organizational topics.
\n\n
				The Fri3d Camp team"
		Email.send email
		return
	"user_exists": (email)->
		console.log "Checking email #{email}"
		user = Meteor.users.findOne({"emails.address":email})
		if user
			return true
		return


Accounts.validateNewUser (user)->
	if !user.emails || user.emails.length is 0
		throw new Meteor.Error 500, "An email address is required to create a user"
	# Email validation:
	address = user.emails[0].address
	url = "https://api.mailgun.net/v2/address/validate"
	pubkey = Meteor.settings.mailgun_pubkey
	check = HTTP.get url,{auth:"api:#{pubkey}",params:{"address":address}}
	if check.data && !check.data.is_valid
		throw new Meteor.Error 500, "Email address did not pass validation"
	return true
