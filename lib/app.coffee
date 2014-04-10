@Registrations = new Meteor.Collection "registrations"

Registrations.allow
	remove: (userId,doc)-> doc.owner is userId
