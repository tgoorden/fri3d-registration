fri3d-registration
==================

Fri3d Hacker Camp registration app (Meteor based).

To run this you need to have installed Meteor and Meteorite (http://oortcloud.github.io/meteorite/).

Run from the checkout directory by using:
```
mrt --settings <settings.json>
```

Where you need to specify the location of a private json file, which should look like this:

```
{"mailgun_pubkey":"<mailgun-key>","public":{"launch":"2014-04-15T12:00"}}
```

The "launch" key is used for the countdown timer. Keep in mind that this should be set in the UTC timezone, to avoid server vs client mismatches.

The mailgun key is not crucial, unless you wish to try out mail stuff.
