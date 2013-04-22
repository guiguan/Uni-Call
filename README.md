[Skype-Call](http://guiguan.github.com/Skype-Call/)
==========

An [Alfred](http://www.alfredapp.com) workflow to make Skype phone call to the phone number selected by Alfred's Address Book feature. If the Skype hasn't been opened yet, this workflow will open it and ensure it is online before starting the phone call. When making a phone call, this workflow won't change your Skype online status, and no annoying confirmation dialog box will be popped up.

The alternative url scheme *skype:{query}?call* approach is not able make a phone call when Skype hasn't been opened in some system environment, such as Mac OS X 10.8.3, and the alternative approach will cause the annoying confirmation dialog to be popped up every time when you try to make a phone call.

This workflow has been tested on Skype 6.3.0.602 and Alfred 2.0.3 (187).

Installation
----------------

### For Alfred v2
1. Make sure the [Alfred](http://www.alfredapp.com) with [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest workflow: [Skype-Call.alfredworkflow 2.0](http://www.guiguan.net/downloads/Skype-Call.alfredworkflow)
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
	call guiguandotnet

### search for a contact, select a phone number or a Skype username and hit return
![Search for A Contact](https://github.com/guiguan/Skype-Call/raw/master/Search-for-A-Contact.png)
![Select A Phone Number](https://github.com/guiguan/Skype-Call/raw/master/Select-A-Phone-Number.png)

Troubleshooting
----------------

### If nothing happens
This is a known issue for Skype-Call.alfredextension 1.0 if you are using a non-english Skype (depends on your Mac OS X language). However, this should have already been fixed in Skype-Call.alfredworkflow 2.0. If by any change, you still encounter a similar problem, please remove the *AppleScript* entry from the "Skype main menu > Skype > Manage API Clients..." dialog (as shown in the following figure), and restart your Skype.

![Manage API Clients](https://github.com/guiguan/Skype-Call/raw/master/Manage-API-Clients.png)

Support
----------------
Please file any issue from [here](https://github.com/guiguan/Skype-Call/issues/new). Alternatively, you can leave comment on [my blog page](http://www.guiguan.net/alfred-workflow-skype-call-2-0/).

Credit
----------------
[Guan Gui](http://www.guiguan.net)