@Registrations = new Meteor.Collection "registrations"

@Tickets = new Meteor.Collection "tickets"
@Merchandising = new Meteor.Collection "merchandising"
@Tokens = new Meteor.Collection "tokens"

Registrations.allow
	remove: (userId,doc)-> doc.owner is userId

Tickets.allow
	remove: (userId,ticket)-> ticket.owner is userId and ticket.paid is false

Merchandising.allow
	remove: (userId,merch)-> merch.owner is userId and merch.paid is false

Tokens.allow
	remove: (userId,tokens)-> tokens.owner is userId and tokens.paid is false
