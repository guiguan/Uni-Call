![Uni Call Logo](https://github.com/guiguan/Uni-Call/raw/master/Uni-Call-Logo.png)

[Uni Call](http://guiguan.github.com/Uni-Call/)
==========

Uni Call is an [Alfred](http://www.alfredapp.com) workflow providing the fastest way to make whatever phone call on your Mac OS X (ambitious :). It will look for information stored in your Apple Contacts (we love the address book :) to help you initiate your phone call as quickly as possible. Right now, with Uni Call, you can make [Skype](#skype-call), [FaceTime](#facetime-call), [bluetooth](#phone-amego-call) (via Phone Amego), [SIP](#sip-call) (via Telephone), [PushDialer](#pushdialer-call) and [Google Voice](#growlvoice-call) (via GrowlVoice) phone call. However, more call methods could be added. Please let me know if you are interested!

![Uni Call](https://github.com/guiguan/Uni-Call/raw/master/Uni-Call.png)

Uni Call workflow supports [Alleyoop auto-updater](http://www.alfredforum.com/topic/1582-alleyoop-update-alfred-workflows/). It has been tested on Skype 6.4.0.833, FaceTime 2.0 (1080), Phone Amego 1.4_9, Telephone 1.0.4 (104), PushDialer 1.7 (Build 64), GrowlVoice 2.0.3 (30) and Alfred 2.0.3 (187).

If you like Uni Call, you can make a small donation to [me](http://www.guiguan.net) via PayPal as to show your thanks and support for my work :)

[![Donate](http://www.paypalobjects.com/en_AU/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=2QBXQLYQNF552&lc=AU&item_name=Uni%20Call&item_number=Uni%20Call&currency_code=AUD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

Installation & Upgrade
--------------

1. Make sure the [Alfred](http://www.alfredapp.com) (with version 2 and above) and [Powerpack](http://www.alfredapp.com/powerpack) is installed
2. Download the latest workflow: [Uni-Call.alfredworkflow 5.1](http://www.guiguan.net/downloads/Uni-Call.alfredworkflow)
3. Double click on the downloaded workflow file to install
4. Type the following command in your Alfred:

		call --updatealfredpreferences yes

5. (Optional) If you have used previous version of Uni Call, new components introduced in a new version are disabled by default. To enable them please refer to [Enable/disable Call Components](#enabledisable-call-components). 

Detailed Usage
--------------

When you would like to make a call, simply type:

	call TARGET

where the TARGET could be:

1. a phone number ([Skype](#skype-call), [FaceTime](#facetime-call), [Phone Amego](#phone-amego-call), [SIP](#sip-call), [PushDialer](#pushdialer-call), [GrowlVoice](#growlvoice-call))
2. a Skype username ([Skype](#skype-call))
3. an email address ([FaceTime](#facetime-call))
4. a SIP address ([SIP](#sip-call))
5. combination of contact details stored in your Apple Contacts: first/last names or corresponding phonetic names, nicknames, organisations (All)

When typing the TARGET, the top N closest fuzzy matching results drawn from Apple Contacts will be provided to you in a timely manner. You can choose one of the results to start the call immediately. Meanwhile, you can use the following options to control your search:


1. Any combination of the following options, the order of which will determine the order of results for each person in your Apple Contacts. Also, you can use options anywhere in your call query.

		call -sf TARGET		# search Skype and FaceTime
		call TARGET -p!f	# search Phone Amego and FaceTime without thumbnails
		call -sfp! TARGET	# equivalent to call -a! TARGET
		callp TARGET -f     # search Phone Amego and FaceTime
		calli TAR -s GET    # search SIP and Skype

2. **-!**: prohibit contact thumbnails caching

		call -!a TARGET		# search for all without thumbnails
		call -s! TARGET		# search for Skype without thumbnails

3. **-a**: lay out all possible call options for your contact (default)

		call -a TARGET
		call TARGET
	
4. **-s**: make a [Skype call](#skype-call) to your contact

		call -s TARGET
		calls TARGET
		
5. **-f**: make a [FaceTime call](#facetime-call) to your contact

		call -f TARGET
		callf TARGET
		
6. **-p**: make a [bluetooth phone call](#phone-amego-call) to your contact via Phone Amego

		call -p TARGET
		callp TARGET
		callp TARGET /DEVICE_ALIAS_OR_DEVICE_LABEL  # select a device to use [*].

	[*] Please refer to [Manage Aliases for Device Labels](#manage-aliases-for-device-labels)
		
7. **-i**: make a [SIP call](#sip-call) to your contact via Telephone

		call -i TARGET
		calli TARGET

8. **-d**: make a [PushDialer call](#pushdialer-call) to your contact

		call -d TARGET
		calld TARGET

9. **-g**: make a [Google Voice call](#growlvoice-call) to your contact via GrowlVoice

		call -g TARGET
		callg TARGET

Alternatively, you can make calls using Alfred's Contacts Feature. There will be six contact actions available for you to choose from in **_Alfred's Contacts Feature_** (under Alfred Preferences > Features > Contacts): [Skype Call](#skype-call), [FaceTime Call](#facetime-call), [Phone Amego Call](#phone-amego-call), [SIP Call](#sip-call), [PushDialer Call](#pushdialer-call) and [GrowlVoice Call](#growlvoice-call).

![Integrate Uni-Call with Alfred's Contacts Feature](https://github.com/guiguan/Uni-Call/raw/master/Alfred-Contacts-Feature.png)

### Enable/disable Call Components

If you only make use of several call components in your daily life, you can completely disable others. Then your Uni Call will act as if it only has those call components working internally. In reality, this will also speedup your Uni Call.

To disable call components:

	call --disable

To re-enable disabled call components:

	call --enable

When a call component is disabled, its corresponding Alfred Preferences will be automatically removed; later when it is enabled again, its Alfred Preferences will then be automatically restored.

Your decision about which call components to enable will be stored persistently in ~/Library/Application Support/Alfred 2/Workflow Data/net.guiguan.Uni-Call/config.plist. The meaning of "persistently" is that your decision will be kept even after you upgrade to future Uni Call versions.

### Contact Thumbnail Cache

In order to present you your contact thumbnails in search results, Uni Call will cache thumbnails (32x32 pixels for each, don't know how retina display users feel about this, let me know) in ~/Library/Application Support/Alfred 2/Workflow Data/net.guiguan.Uni-Call/thumbnails/. Their lifespans will be one week. By default, only those contacts have been searched for will have their thumbnails cached, so the next time, when you search for the same contacts, they will load faster. However, you can use:

	call --buildfullthumbnailcache yes

to build a full thumbnail cache for all your contacts from Apple Contacts.

If you decided not to show contact thumbnails, you can completely remove the cache using:

	call --destroythumbnailcache yes

and then use -! option along with other search options to prohibit the automatic thumbnail generation and caching. You can change script filters to adopt -! option too.

### Skype Call
--------------

Skype Call requires the newest version of [Skype](http://www.skype.com/en/download-skype/skype-for-mac/).

Among the search results for Skype Call, contact thumbnails will be shown in color:#47baec border:

![Skype](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-Skype.png)

If the Skype user corresponding to a particular Skype username is detected online (Skype has to be opened for the detection to work), his or her thumbnail will be shown in color:#47baec border with color:#47baec inner shadow:

![Skype Online](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-Skype-Online.png)

If the Skype hasn't been opened yet, Skype Call will open it and ensure it is online before starting the phone call. When making a phone call, Skype Call won't change your Skype online status, and no annoying confirmation dialog box will be popped up.

The alternative url scheme *skype:{query}?call* approach is not able make a phone call when Skype hasn't been opened in some system environment, and it will also cause the annoying confirmation dialog to be popped up every time when you try to make a Skype call.

#### The Correct Way to Store a Skype Username for Your Contact
1. Retrieve your contact's Skype username from Skype App

![Skype Username](https://github.com/guiguan/Uni-Call/raw/master/Skype-Username.png)

2. Store the Skype username in the IM (Instant Message) field, and select Skype as the IM type

![Apple-Contacts](https://github.com/guiguan/Uni-Call/raw/master/Apple-Contacts.png)

### FaceTime Call
-----------------

FaceTime Call requires the newest version of [FaceTime](http://www.apple.com/au/mac/facetime/).

Among the search results for FaceTime Call, contact thumbnails will be shown in color:#f74598 border:

![FaceTime](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-FaceTime.png)

You can nominate a particular phone or email field of a person in Apple Contacts to be FaceTime Call targets of your choice, which will opt out other phone numbers and emails to be shown in the searching results. To do so, simply put a customized label, either **_FaceTime_**, **_iPhone_**, **_iPad_** or **_iDevice_** in front of phone or email nominees:

![FaceTime Nomination](https://github.com/guiguan/Uni-Call/raw/master/FaceTime-Nomination.png)

You can also use comma to separate multiple labels. For example, using label "iPhone, home" in front of a phone number will nominate that phone number as well as labelling that number as "home" in the Uni Call search results. Note that the label "iPhone" is only used for target nomination, but not used to label Uni Call search results.

The thumbnail of a person who has nominated phone number or email will be shown in color:#f74598 border with color:#f74598 inner shadow:

![FaceTime Nominated](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-FaceTime-Nominated.png)

FaceTime Call uses url scheme *facetime:{query}* to launch FaceTime and start a call.

### Phone Amego Call
--------------------

With the help of [Phone Amego](http://www.sustworks.com/pa_guide/), you can turn your Mac into a bluetooth headset and remotely control your real mobile phone to start and receive real phone calls. Sweet?!

Phone Amego Call requires the newest version of [Phone Amego](http://www.sustworks.com/pa_guide/).

Among the search results for Phone Amego Call, contact thumbnails will be shown in color:#fcbd5a border:

![Phone Amego](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-PhoneAmego.png)

Phone Amego Call uses url scheme *phoneAmego:{query};alert=no* to launch Phone Amego and start a call.

#### Manage Aliases for Device Labels

You can assign an easy to remember alias to a complicated device label. For example:

	callp --map ip to "Guan's iPhone" yes

Then in the future you can make a bluetooth phone call through device "Guan's iPhone" as follows:

	callp TARGET /ip

To remove the assigned alias:

	callp --unmap ip yes

### SIP Call
------------

SIP Call requires the newest version of [SIP](http://voip.about.com/od/sipandh323/a/What-Is-Sip-And-What-Is-It-Good-For.htm) client [Telephone](http://www.tlphn.com/).

Among the search results for SIP Call, contact thumbnails will be shown in color:#fcbd5a border:

![SIP](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-SIP.png)

If you store a SIP address in a contact's Url field with custom label "sip", such as follows:

![SIP Record](https://github.com/guiguan/Uni-Call/raw/master/SIP-Record.png)

then the corresponding thumbnail for that person will be shown in color:#fcbd5a border with color:#fcbd5a inner shadow:

![SIP Recorded](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-SIP-Recorded.png)

SIP Call uses url scheme *tel:{query}* for phone numbers and url scheme *sip:{query}* for SIP addresses to launch Telephone and start a call.

### PushDialer Call
-------------------

PushDialer Call requires the newest version of [PushDialer](http://pushdialer.com/).

Among the search results for PushDialer Call, contact thumbnails will be shown in color:#9e5132 border:

![PushDialer](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-PushDialer.png)

PushDialer Call uses url scheme *pushdialer://{query}* to launch PushDialer and start a call. By default, PushDialer will send out a Growl notification to confirm a dialling out.

### GrowlVoice Call
-------------------

GrowlVoice Call requires the newest version of [GrowlVoice](http://www.growlvoice.com/).

Among the search results for GrowlVoice Call, contact thumbnails will be shown in color:#37a940 border:

![GrowlVoice](https://github.com/guiguan/Uni-Call/raw/master/defaultContactThumbnail-GrowlVoice.png)

GrowlVoice Call uses url scheme *growlvoice:{query}* to launch GrowlVoice and start a call.

### CallTrunk Call
------------------

### Fritz!Box Call
------------------

Support
----------------
Please file any issue from [this GitHub issue tracker](https://github.com/guiguan/Uni-Call/issues/new). Alternatively, you can leave comments on [my blog page](http://www.guiguan.net/uni-call). Or, you can post on the [Uni Call topic section of Alfred forum](http://www.guiguan.net/redirections/Alfred-Forum-Uni-Call).

Credit
----------------
[Guan Gui](http://www.guiguan.net)

Changelog
----------------
#### v5.1 (07/06/13)
* Fixed a minor bug of Skype Call that could prevent non-English platform from working properly
* Added CallTrunk Call component. The user can use --setdefaultcountry long option to set a default country specific Call Trunk to use. Also, the user can provide an extra parameter to overwrite the default country, for example, using "callk guan gui /au" to call Guan Gui via AU version of Call Trunk.
* Added Fritz!Box Call component

#### v5.03 (23/05/13)
* Now those labels for phone number fields in Apple Contacts are shown in front of phone numbers in Uni Call, which can allow you to quickly recognise right phone number target for business, for home etc. Multiple labels can also be used, which are separated by commas. Therefore, you can use FaceTime target nomination along with traditional contact labels, such as using label "iPhone, home".

#### v5.02 (21/05/13)
* Minor bug fixes: now Uni Call will at least fully output results for one matched contact before enforcing result number limit to improve the responsiveness.

#### v5.01 (20/05/13)
* Minor bug fixes: now even if a TARGET is not identified in Apple Contacts, user's preferences of the TARGET's call options will be learnt as well

#### v5.0 (19/05/13)
* Added SIP Call component
* Added PushDialer Call component
* Added GrowlVoice Call component
* Update for Phone Amego Call: the user can select which bluetooth device to use ("callp TARGET /DEVICE_ALIAS_OR_DEVICE_LABEL") for making a phone call. The user can also assign an easy to remember alias to a complicated device label.
* Now the user can completely enable/disable call components through "call --enable"/"call --disable". When a call component is disabled, its corresponding Alfred Preferences will be automatically removed; later when it is enabled again, its Alfred Preferences will then be automatically restored.
* The thumbnail cache folder is now moved from ~/Library/Caches/net.guiguan.Uni-Call/thumbnails to ~/Library/Application Support/Alfred 2/Workflow Data/net.guiguan.Uni-Call/thumbnails, which ensures that Uni Call will be uninstalled with Alfred 2.
* Added a persistent configuration file config.plist in ~/Library/Application Support/Alfred 2/Workflow Data/net.guiguan.Uni-Call. The reason why this config.plist is not placed inside Uni Call workflow folder but in Workflow Data folder is to make sure that the user's configurations will stay unchanged after future workflow upgrades.

#### v4.21 (14/05/13)
* Minor bug fixes: now handles spaces in POSIX path to the workflow. Before, those spaces could cause problem for Uni Call Basestation to launch Uni Call.
* Minor bug fixes: Skype Call can now correctly generate notifications in Mac OS X Notification Centre.

#### v4.2 (12/05/13)
* The original Uni Call executable is now divided into two separate parts: the Uni Call Basestation and the Uni Call. The Uni Call Basestation is the one invoked everytime by Alfred, while the Uni Call is in turn spawned by Uni Call Basestation, which will continue to run in the background unless idling for 5 min. Basically, the Uni Call will sit there and wait to serve requests come from Uni Call Basestation (via TCP port number 28642). In this way, the consecutive requests come from Alfred could be served more quickly by Uni Call. In fact, it does improve the response time by 50% (Refer to the following figure)!

![Uni Call v4.2 Performance](https://github.com/guiguan/Uni-Call/raw/master/Uni-Call-42-Performance.png)

* Options can now be used everywhere among the query. So "call guan -s gui" is equivalent to "call -s guan gui" and "call guan gui -s".

#### v4.1 (7/05/13)
* Did some performance tweak. Now Uni Call runs much faster.

#### v4.0 (4/05/13)
* Big changes to original Skype Call workflow and renamed it to Uni Call. FaceTime and Phone Amego Call components are introduced.

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
