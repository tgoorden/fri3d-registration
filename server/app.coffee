@StripeLog = new Meteor.Collection 'stripelog'

Meteor.publish "registrations", ()-> Registrations.find {},{fields:{remarks:0}}

Meteor.publish "userData", ()->
	if this.userId
		user =  Meteor.users.findOne {_id:this.userId}, {fields:{"role":1}}
		if user.role is "admin"
			return Meteor.users.find {}, {fields:{"role":1,"emails":1}}
		else
			return Meteor.users.find {_id:this.userId}, {fields:{"role":1}}
	else
		this.ready()
	return

Meteor.publish "tickets", ()-> Tickets.find {owner:this.userId}

Meteor.publish "other_tickets", ()-> Tickets.find {owner:{$ne:this.userId}},{fields:{"_id":1}}

Meteor.publish "merchandising", ()-> Merchandising.find {owner:this.userId}

Meteor.publish "tokens", ()-> Tokens.find {owner:this.userId}

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
		# console.log "Checking email #{email}"
		user = Meteor.users.findOne({"emails.address":email})
		if user
			return true
		return
	"mailing": (subject,body)->
		if !Meteor.user() or Meteor.user().role isnt "admin"
			throw new Meteor.Error 403,"You have to be logged in as administrator"
		email =
			from: "Fri3d Camp Support <general@support.fri3d.be>"
			subject: subject
			text: body
		Meteor.users.find({}).forEach (user)->
			console.log EJSON.stringify user
			email.to = user.emails[0].address
			Email.send email
	"addticket": (ticket)->
		if !Meteor.userId()
			throw new Meteor.Error 403, "You have to be logged in"
		required = [
			{"key":"first_name","label":"First name"}
			{"key":"last_name","label":"Last name"}
			{"key":"birthday","label":"Birthday"}
			{"key":"type","label":"Ticket type"}
		]
		_.each required, (field)->
			if !ticket[field.key] or ticket[field.key] is ""
				throw new Meteor.Error 500, "#{field.label} is required"
		pick = _.pick ticket, "first_name","last_name","birthday", "type", "volunteer","veggie","arrival","departure"
		pick.owner = Meteor.userId()
		tt = _.findWhere tickettypes, {type: ticket.type}
		if !tt
			throw new Meteor.Error 500, "Unknown ticket type: #{ticket.type}"
		pick.amount = tt.cost
		pick.paid = false
		pick.created = new Date()
		Tickets.insert pick
		return
	"addmerchandising": (size)->
		if !Meteor.userId()
			throw new Meteor.Error 403, "You have to be logged in"
		tshirt =
			size: size
			owner: Meteor.userId()
			created: new Date()
			amount: 15
			paid: false
		Merchandising.insert tshirt
		return
	"addtokens": (size)->
		if !Meteor.userId()
			throw new Meteor.Error 403, "You have to be logged in"
		tokens=
			owner: Meteor.userId()
			created: new Date()
			amount: 10
			paid: false
		Tokens.insert tokens
		return
	"creditcard_payment": (card) ->
		if !Meteor.userId()
			throw new Meteor.Error 403, 'You have to be logged in'
		# let's get total charges
		total = 0
		ticket_ids = []
		merchandising_ids = []
		tokens_ids = []
		Tickets.find({owner:Meteor.userId(),paid:false}).forEach (ticket)->
			total += ticket.amount
			ticket_ids.push ticket._id
		Merchandising.find({owner:Meteor.userId(),paid:false}).forEach (merch)->
			total += merch.amount
			merchandising_ids.push merch._id
		Tokens.find({owner:Meteor.userId(),paid:false}).forEach (token)->
			total += token.amount
			tokens_ids.push token._id
		charge =
			amount: total * 100
			currency: "EUR"
			card: card
			description: 'Fri3d Camp - ref: ' + Meteor.userId()
		console.log EJSON.stringify charge
		result = HTTP.post "https://api.stripe.com/v1/charges", {params: charge,headers: {"content-type": "application/x-www-form-urlencoded"}, timeout: 20000, auth: Meteor.settings.stripe_sk + ':'}
		StripeLog.insert({user:this.userId,'created':new Date(),result})
		Tickets.update {_id:{$in:ticket_ids}},{$set:{paid:true}},{multi:true}
		Merchandising.update {_id:{$in:merchandising_ids}},{$set:{paid:true}},{multi:true}
		Tokens.update {_id:{$in:tokens_ids}},{$set:{paid:true}},{multi:true}
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
