[Skype Call](http://guiguan.github.com/Skype-Call/)
==========

Skype Call is an [Alfred](http://www.alfredapp.com) workflow providing the fastest way to make a Skype call on Mac OS X.

![Skype Call](https://github.com/guiguan/Skype-Call/raw/master/Skype-Call.png)

When you would like to make a Skype call, simply type:

	call TARGET

where TARGET could be:

1. a Skype username (the icon of online users will be shown as green)
2. a phone number
3. combination of contact details stored in your Apple Contacts: first/last names or corresponding phonetic names, nicknames, organisations

or alternatively, you can make Skype call using Alfred's Contacts feature. 

If the Skype hasn't been opened yet, this workflow will open it and ensure it is online before starting the phone call. When making a phone call, this workflow won't change your Skype online status, and no annoying confirmation dialog box will be popped up.

The alternative url scheme *skype:{query}?call* approach is not able make a phone call when Skype hasn't been opened in some system environment, and it will also cause the annoying confirmation dialog to be popped up every time when you try to make a phone call.

This workflow supports [Alleyoop auto-updater](http://www.alfredforum.com/topic/1582-alleyoop-update-alfred-workflows/), and it has been tested on Skype 6.3.0.602 and Alfred 2.0.3 (187).

Installation
----------------

### For Alfred v2
1. Make sure the [Alfred](http://www.alfredapp.com) with [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest workflow: [Skype-Call.alfredworkflow 3.0](http://www.guiguan.net/downloads/Skype-Call.alfredworkflow)
3. Double click on the downloaded workflow file to install
4. Under "Alfred Preferences > Features > Contacts", add two custom actions for both Phone and Skype as shown in the following figure.

![Integrate Skype-Call with Alfred's Contacts feature](https://github.com/guiguan/Skype-Call/raw/master/Alfred-Preferences-v2.png)

### For Alfred v1 (workflows were known as extensions back then)
1. Make sure the [Alfred](http://www.alfredapp.com) with [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest extension: [Skype-Call.alfredextension 1.0](http://www.guiguan.net/downloads/Skype-Call.alfredextension)
3. Double click on the downloaded extension file to install
4. Select Skype-Call from drop-down menu in "Alfred Preferences > Features > Address Book > General > Phone" as shown in the following figure.

![Integrate Skype-Call with Alfred's Address Book feature](https://github.com/guiguan/Skype-Call/raw/master/Alfred-Preferences.png)

Usage
----------------

### type "call PHONE_NUMBER"
	call +61 4 3333 3333
	call 043333333

### type "call SKYPE_USERNAME"
	call echo123
![Skype Username](https://github.com/guiguan/Skype-Call/raw/master/Skype-Username.png)

### search for a contact, select a phone number or a Skype username and hit return
![Apple-Contacts](https://github.com/guiguan/Skype-Call/raw/master/Apple-Contacts.png)
![Search for A Contact](https://github.com/guiguan/Skype-Call/raw/master/Search-for-A-Contact.png)
![Select A Phone Number](https://github.com/guiguan/Skype-Call/raw/master/Select-A-Phone-Number.png)

Troubleshooting
----------------

### If nothing happens
This is a known issue for Skype-Call.alfredextension 1.0 if you are using a non-english Skype (depends on your Mac OS X language). However, this should have already been fixed in Skype-Call.alfredworkflow 2.0. If by any change, you still encounter a similar problem, please remove the *AppleScript* entry from the "Skype main menu > Skype > Manage API Clients..." dialog (as shown in the following figure), and restart your Skype.

![Manage API Clients](https://github.com/guiguan/Skype-Call/raw/master/Manage-API-Clients.png)

Support
----------------
Please file any issue from [this GitHub issue tracker](https://github.com/guiguan/Skype-Call/issues/new). Alternatively, you can leave comments on [my blog page](http://www.guiguan.net/skype-call-the-fastest-way-to-make-a-skype-call-on-mac-os-x/). Or, you can post on the [Skype Call topic section of Alfred forum](http://www.alfredforum.com/topic/2216-skype-call-the-fastest-way-to-make-a-skype-call-on-mac-os-x/).

Credit
----------------
[Guan Gui](http://www.guiguan.net)