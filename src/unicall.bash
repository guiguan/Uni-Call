query="$1"

case "$query" in
	"[CTSkype]"*)
		osascript bin/skypecall.scpt ${query#'[CTSkype]'};;
	"[CTFaceTime]"*)
		open "facetime:${query#'[CTFaceTime]'}";;
	"[CTPhoneAmego]"*)
		open "phoneAmego:${query#'[CTPhoneAmego]'};alert=no";;
	"[CTSIP]"*)
		query="${query#'[CTSIP]'}"
		echo "${query//[ -()]/}";;
esac