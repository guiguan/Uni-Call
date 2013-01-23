[Skype-Call](http://guiguan.github.com/Skype-Call/)
==========

An [Alfred](http://www.alfredapp.com) extension to make Skype phone call to the phone number selected by Alfred's Address Book feature. If the Skype hasn't been opened yet, this extension will open it and ensure it is online before starting the phone call. When making a phone call, this extension won't change your Skype online status, and no annoying confirmation dialog box will be popped up.

The alternative url scheme *skype:{query}?call* approach is not able make a phone call when Skype hasn't been opened in some system environment, such as Mac OS X 10.8 Developer Preview 3, and the alternative approach will cause the annoying confirmation dialog to be popped up every time when you try to make a phone call.

This extension is compatible with David Ferguson's [Extension Updater for Alfred](http://jdfwarrior.tumblr.com/post/13826478125/extension-updater), and it has been tested on Skype 5.7.0.1037 and Alfred 1.2 (220).

Installation
----------------

1. Make sure the [Alfred](http://www.alfredapp.com) with [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest extension: [Skype-Call.alfredextension 1.0](http://www.guiguan.net/downloads/Skype-Call.alfredextension)
3. Double click on the downloaded extension file to install
4. Select Skype-Call from drop-down menu in "Alfred Preferences > Address Book > General > Phone" as shown in following figure.

![Integrate Skype-Call with Alfred's Address Book feature](https://github.com/guiguan/Skype-Call/raw/master/Alfred-Preferences.png)

Usage
----------------

### type "call PHONE_NUMBER"
	call +61 4 3333 3333
	call 043333333

### type "call SKYPE_USERNAME"
	call guiguandotnet

### search for a contact, select a phone number and hit return
![Search for A Contact](https://github.com/guiguan/Skype-Call/raw/master/Search-for-A-Contact.png)
![Select A Phone Number](https://github.com/guiguan/Skype-Call/raw/master/Select-A-Phone-Number.png)

Support
----------------
Please file any issue from [here](https://github.com/guiguan/Skype-Call/issues/new). Alternatively, you can leave comment on [my blog page](http://www.guiguan.net/alfred-extension-skype-call-1-0/).

Credit
----------------
[Guan Gui](http://www.guiguan.net)