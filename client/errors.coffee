# 
# Based on https://github.com/carlh/Meteor-book-errors
# Added the ability to attach an error to a "selector", 
# so it can be put in specific spots in a template
# using {{showError 'selector'}}.
#

@Errors =
	collection: new Meteor.Collection null
	throw: (message,selector)-> 
		# the error might be something thrown server side
		# in this case we only hang on to the "reason"
		message = message.reason || message
		error =
			"message":message
			"seen":false
		error.selector = selector if selector
		Errors.collection.insert error
	clear: (selector)->
		if selector
			Errors.collection.remove {"selector":selector}
		else
			Errors.collection.remove {"seen":true}
	clearAll: ()->
			Errors.collection.remove {}

Handlebars.registerHelper "hasError", (selector)->
	hasError = if Errors.collection.findOne({"selector":selector}) then true else false
	return hasError

Handlebars.registerHelper "showError", (selector)->
	error = Errors.collection.findOne({"selector":selector})
	if error
		Meteor.defer ()-> Errors.collection.update error._id, {$set:{"seen":true}}
		return error.message
	return

Handlebars.registerHelper "errorStatus", (selector)->
	hasError = if Errors.collection.findOne({"selector":selector}) then true else false
	return "has-error has-feedback" if hasError


