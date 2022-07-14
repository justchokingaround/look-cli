#!/bin/sh
# FOR NOW THIS ONLY WORKS WITH MOVIES AND THE SID AND SECRET ARE HARDCODED

base="https://lookmovie2.to"

[ -z "$*" ] && printf "Enter a Movie name: " && read -r query || query=$*
query=$(printf "%s" "$query"|tr " " "%20")
show_page="$base"$(curl -s "https://lookmovie2.to/movies/search/?q=$query"|tr -d "\n"|grep -Eo '<h6>.+?</a>'|
  sed -En 's_.*href="([^"]*)">(.*)</a>_\1\2_p'|fzf --height=8 --with-nth 2..|cut -d' ' -f1)

###### CAPTCHA STUFF ######

# recaptcha_link=$(curl -s "$show_page"|grep recaptcha|sed -En 's_.*script src="([^"]*)".*_\1_p')
# v=$(curl -s "$recaptcha_link"|
#   sed -En "s_.*po.src='.*/(.*)/recaptcha.*_\1_p")
# k="6LdPO70aAAAAAPLTFBiLkiyTlzco6VNnD0Y6jP3b"

# curl -s "https://www.google.com/recaptcha/api2/anchor?ar=1&k=${k}&hl=en&v=${v}&size=invisible&cb=j34k5o3kbxzl"

###### CAPTCHA STUFF ######

sid="o0d77am4jdpgd10h013pehetm4"
sec="cac85a7fc72edfa478b3f759b7eea6e91bb12981"
build_url=$(printf "%s" "$show_page?&sid=${sid}&sec=${sec}"|
  sed 's_.*view/_https://playerwatchlm10.xyz/movies/play/_g')
url=$(curl -sL "$build_url")

id=$(printf "%s" "$url"|sed -En "s@.*id_movie: ([0-9]*).*@\1@p")
hash=$(printf "%s" "$url"|sed -En 's_.*hash: "([^"]*)".*_\1_p')
expires=$(printf "%s" "$url"|grep "expires"|sed 's/[^0-9]//g')
links_url=$(curl -s "https://playerwatchlm10.xyz/api/v1/security/movie-access?id_movie=${id}&hash=${hash}&expires=${expires}"|tr "{|}|," "\n")

low_quality="$(printf "%s" "$links_url"|sed -En 's_"480p":"([^"]*)"_\1_p'))"
medium_quality="$(printf "%s" "$links_url"|sed -En 's_"720p":"([^"]*)"_\1_p')"
high_quality="$(printf "%s" "$links_url"|sed -En 's_"1080p":"([^"]*)"_\1_p')"

# only the first 4 english subs, otherwise mpv will take forever to load
subs=$(printf "%s" "$links_url"|sed -En 's_"file":"([^"]*)"_\1_p'|grep -m4 "en"|sed -e "s_^_${base}_g" -e 's/:/\\:/g'|tr "\n" ":"|sed 's/:$//')

# TODO: simplify this
if [ -z "$high_quality" ] && [ -z "$medium_quality" ] && [ -z "$low_quality" ]; then
  printf "No links found\n"
  exit 1
elif [ -z "$high_quality" ] && [ -z "$medium_quality" ]; then
  mpv --sub-files="$subs" "$low_quality"
elif [ -z "$high_quality" ]; then
  mpv --sub-files="$subs" "$medium_quality"
else
  mpv --sub-files="$subs" "$high_quality"
fi

