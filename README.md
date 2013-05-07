[Uni Call](http://guiguan.github.com/Uni-Call/)
==========

Uni Call is an [Alfred](http://www.alfredapp.com) workflow providing the fastest way to make Skype, FaceTime or bluetooth phone call (via [Phone Amego](http://www.sustworks.com/pa_guide/)) on Mac OS X. It is renamed from previous Skype Call workflow. Right now, Uni Call comprises three call components: Skype Call, FaceTime Call and Phone Amego Call, but more could be added (Please let me know if you are interested in using a new way to call:)). 

![Uni Call](https://github.com/guiguan/Uni-Call/raw/master/Uni-Call.png)

When you would like to make a call, simply type:

	call TARGET

where the TARGET could be:

1. a phone number (Skype, FaceTime, Phone Amego)
2. a Skype username (Skype)
3. an email address (FaceTime)
4. combination of contact details stored in your Apple Contacts: first/last names or corresponding phonetic names, nicknames, organisations (All)

When typing the TARGET, the top N closest fuzzy matching results drawn from Apple Contacts will be provided to you in a timely manner. You can choose one of the results to start the call immediately. Meanwhile, you can use the following options to control your search:

1. **-a**: lay out all possible call options for your contact (default)

		call -a TARGET
		call TARGET
	
2. **-s**: make a Skype call to your contact

		call -s TARGET
		calls TARGET
		
3. **-f**: make a FaceTime call to your contact

		call -f TARGET
		callf TARGET
		
4. **-p**: make a bluetooth phone call to your contact via Phone Amego

		call -p TARGET
		callp TARGET
		
5. **-!**: prohibit contact thumbnails caching

		call -!a TARGET		# search for all without thumbnails
		call -s! TARGET		# search for Skype without thumbnails
		
6. Combination of the above options, the order of which will determine the order of results for each person in your Apple Contacts

		call -sf TARGET		# search Skype and FaceTime
		call -p!f TARGET	# search Phone Amego and FaceTime without thumbnails
		call -sfp! TARGET	# equivalent to call -a! TARGET

Alternatively, you can make calls using Alfred's Contacts Feature. There will be three contact actions available for you to choose from in **_Alfred's Contacts Feature_**: Skype Call, FaceTime Call and Phone Amego Call.

Uni Call workflow supports [Alleyoop auto-updater](http://www.alfredforum.com/topic/1582-alleyoop-update-alfred-workflows/). It has been tested on Skype 6.3.0.602, FaceTime 2.0 (1080), Phone Amego 1.4_9 and Alfred 2.0.3 (187).

### Skype Call
--------------

Among the search results for Skype Call, contact thumbnails will be shown in sky-blue border:

![Skype](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-Skype.png)

If the Skype user corresponding to a particular Skype username is detected online (Skype has to be opened for the detection to work), his or her thumbnail will be shown in sky-blue border with sky-blue inner shadow:

![Skype Online](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-Skype-Online.png)

If the Skype hasn't been opened yet, Skype Call will open it and ensure it is online before starting the phone call. When making a phone call, Skype Call won't change your Skype online status, and no annoying confirmation dialog box will be popped up.

The alternative url scheme *skype:{query}?call* approach is not able make a phone call when Skype hasn't been opened in some system environment, and it will also cause the annoying confirmation dialog to be popped up every time when you try to make a Skype call.

### FaceTime Call
-----------------

Among the search results for FaceTime Call, contact thumbnails will be shown in pink border:

![FaceTime](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-FaceTime.png)

You can nominate a particular phone or email field of a person in Apple Contacts to be FaceTime Call targets of your choice, which will opt out other phone numbers and emails to be shown in the searching results. To do so, simply put a customized label, either **_FaceTime_**, **_iPhone_** or **_iDevice_** in front of phone or email nominees:

![FaceTime Nomination](https://github.com/guiguan/Uni-Call/raw/master/FaceTime-Nomination.png)

The thumbnail of a person who has nominated phone number or email will be shown in pink border with pink inner shadow:

![FaceTime Nominated](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-FaceTime-Nominated.png)

FaceTime Call uses url scheme *facetime:{query}* to launch FaceTime and start a call.

#### The Correct Way to Store a Skype Username for Your Contact
1. Retrieve your contact's Skype username from Skype App

![Skype Username](https://github.com/guiguan/Uni-Call/raw/master/Skype-Username.png)

2. Store the Skype username in the IM (Instant Message) field, and select Skype as the IM type

![Apple-Contacts](https://github.com/guiguan/Uni-Call/raw/master/Apple-Contacts.png)

### Phone Amego Call
--------------------

With the help of [Phone Amego](http://www.sustworks.com/pa_guide/), you can turn your Mac into a bluetooth headset and remotely control your real mobile phone to start and receive real phone calls. Sweet?!

Among the search results for Phone Amego Call, contact thumbnails will be shown in yellow border:

![Phone Amego](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-PhoneAmego.png)

Phone Amego Call uses url scheme *phoneAmego:{query};alert=no* to launch Phone Amego and start a call.

Installation & Configuration
----------------

1. Make sure the [Alfred](http://www.alfredapp.com) (with version 2 and above) and [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest workflow: [Uni-Call.alfredworkflow 4.1](http://www.guiguan.net/downloads/Uni-Call.alfredworkflow)
3. Double click on the downloaded workflow file to install
4. (Optional) Under "Alfred Preferences > Features > Contacts":

![Integrate Uni-Call with Alfred's Contacts Feature](https://github.com/guiguan/Uni-Call/raw/master/Alfred-Contacts-Feature.png)

### Contact Thumbnail Cache
In order to present you your contact thumbnails in search results, Uni Call will cache thumbnails (32x32 pixels for each, don't know how retina display users feel about this, let me know) in /Users/guiguan/Library/Caches/net.guiguan.Uni-Call/thumbnails/. Their lifespans will be one week. By default, only those contacts have been searched for will have their thumbnails cached, so the next time, when you search for the same contacts, they will load faster. However, you can use:

	call -# yes

to build a full thumbnail cache for all your contacts from Apple Contacts.

If you decided not to show contact thumbnails, you can completely remove the cache using:

	call -$ yes

and then use -! option along with other search options to prohibit the automatic thumbnail generation and caching. You can change script filters to adopt -! option too.

Support
----------------
Please file any issue from [this GitHub issue tracker](https://github.com/guiguan/Uni-Call/issues/new). Alternatively, you can leave comments on [my blog page](http://www.guiguan.net/uni-call). Or, you can post on the [Uni Call topic section of Alfred forum](http://www.guiguan.net/redirections/Alfred-Forum-Uni-Call).

Credit
----------------
[Guan Gui](http://www.guiguan.net)

Changelog
----------------
#### v4.1 (7/05/13)
* Did some performance tweak. Now Uni Call runs much faster.

Legacy: Skype-Call.alfredextension 1.0 for Alfred v1
----------------

### Installation
1. Make sure the [Alfred](http://www.alfredapp.com) with [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest extension: [Skype-Call.alfredextension 1.0](http://www.guiguan.net/downloads/Skype-Call.alfredextension)
3. Double click on the downloaded extension file to install
4. Select Skype-Call from drop-down menu in "Alfred Preferences > Features > Address Book > General > Phone" as shown in the following figure.

![Integrate Skype-Call with Alfred's Address Book Feature](https://github.com/guiguan/Uni-Call/raw/master/Alfred-Preferences.png)

### Usage

#### type "call PHONE_NUMBER"
	call +61 4 3333 3333
	call 043333333

#### type "call SKYPE_USERNAME"
	call echo123

#### search for a contact, select a phone number or a Skype username and hit return
![Search for A Contact](https://github.com/guiguan/Uni-Call/raw/master/Search-for-A-Contact.png)
![Select A Phone Number](https://github.com/guiguan/Uni-Call/raw/master/Select-A-Phone-Number.png)

### Troubleshooting

#### If nothing happens
This is a known issue for Skype-Call.alfredextension 1.0 if you are using a non-english Skype (depends on your Mac OS X language). However, this should have already been fixed in Skype-Call.alfredworkflow 2.0. If by any change, you still encounter a similar problem, please remove the *AppleScript* entry from the "Skype main menu > Skype > Manage API Clients..." dialog (as shown in the following figure), and restart your Skype.

![Manage API Clients](https://github.com/guiguan/Uni-Call/raw/master/Manage-API-Clients.png)
