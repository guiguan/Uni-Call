query={query}

case "$query" in
	"[CTSkype]"*)
		osascript skypecall.scpt ${query#'[CTSkype]'};;
	"[CTFaceTime]"*)
		open "facetime:${query#'[CTFaceTime]'}";;
	"[CTPhoneAmego]"*)
		open "phoneAmego:${query#'[CTPhoneAmego]'};alert=no";;
esac