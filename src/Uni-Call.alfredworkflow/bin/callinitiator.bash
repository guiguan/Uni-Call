#!/bin/bash
#
# Call Initiator is used as a single facade for interacting with external call
# related applications
#
# @Author: Guan Gui
# @Date:   2014-11-08 17:36:42
# @Email:  root@guiguan.net
# @Last modified by:   Guan Gui
# @Last modified time: 2015-01-16 17:38:41


query="$1"

# echo "$query" 1> bin/debug_output.txt

case "$query" in
    "[CTSkype]"*)
        open "skype:${query#'[CTSkype]'}";;
    "[CTFaceTime]"*)
        query="${query#'[CTFaceTime]'}"
        if [[ "$query" == "facetime:"* || "$query" == "facetime-audio:"* ]]; then
            open "${query}"
        else
            # dash - might be used in email addresses, FaceTime seems to be
            # fine at handling dashes in query
            open "facetime:${query//[ ()]/}"
        fi;;
    "[CTPhoneAmego]"*)
        open "phoneAmego:${query#'[CTPhoneAmego]'};alert=no";;
    "[CTSIP]"*)
        query="${query#'[CTSIP]'}"
        if [[ "$query" == *"@"* ]]; then
            open "sip:${query#'sip:'}"
        else
            query="${query#'tel:'}"
            open "tel:${query//[ -()]/}"
        fi;;
    "[CTPushDialer]"*)
        open "pushdialer://${query#'[CTPushDialer]'}";;
    "[CTGrowlVoice]"*)
        query="${query#'[CTGrowlVoice]'}"
        if [[ "$query" == *"?"* ]]; then
            open "growlvoice:${query}"
        else
            open "growlvoice:${query//[ -()]/}?call" 
        fi;;
    "[CTCallTrunk]"*)
        osascript bin/calltrunkcall.scpt ${query#'[CTCallTrunk]'};;
    "[CTFritzBox]"*)
        osascript bin/fritzboxcall.scpt ${query#'[CTFritzBox]'};;
    "[CTDialogue]"*)
        open "x-dialogue://${query#'[CTDialogue]'}";;
    "[CTIPhone]"*)
        query="${query#'[CTIPhone]'}"
        open "tel:${query//[ -()]/}";;
    "[CTMessages]"*)
        query="${query#'[CTMessages]'}"
        if [[ "$query" == "xmpp:"* ]]; then
            open "${query}"
        else
            query="${query#'imessage:'}"
            # dash - might be used in email addresses, Messages seems to be
            # fine at handling dashes in query
            query="${query//[ ()]/}"
            osascript bin/openimessagetarget.scpt "${query}"
        fi;;
    "[CTWeChat]"*)
        query="${query#'[CTWeChat]'}"
        query="${query#'weixinmac://chat/'}"
        osascript bin/openwechattarget.scpt "${query}";;
    "[ContactAuthor]"*)
        open "${query#'[ContactAuthor]'}";;
    "[Cmd]"*)
        eval "${query#'[Cmd]'}";;
esac