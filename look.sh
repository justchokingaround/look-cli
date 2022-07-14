#!/bin/sh

# FOR NOW THIS ONLY WORKS WITH TV SHOWS, AND IT ONLY WORKS WITH THE LAST EPISODE OF THE SEASON

base="https://lookmovie2.to"

# [ -z "$*" ] && printf "Enter a lookmovie link: " && read -r url || url=$*
[ -z "$*" ] && printf "Enter a TV Show name: " && read -r query || query=$*
query=$(printf "%s" "$query"|tr " " "%20")
show_page="$base"$(curl -s "https://lookmovie2.to/shows/search/?q=$query"|tr -d "\n"|grep -Eo '<h6>.+?</a>'|
  sed -En 's_.*href="([^"]*)">(.*)</a>_\1\2_p'|fzf --height=8 --with-nth 2..|cut -d' ' -f1)
# printf "show_page: $show_page\n"

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
  sed 's_.*view/_https://playerwatchlm10.xyz/shows/play/_g')
url=$(curl -sL "$build_url")

id=$(printf "%s" "$url"|sed -En 's@.*id_episode: ([0-9]*),@\1@p'|tail -n1)
hash=$(printf "%s" "$url"|grep "hash"|cut -d"'" -f2)
expires=$(printf "%s" "$url"|grep "expires"|sed 's/[^0-9]//g')

# printf "ID: %s\n" "$id"
# printf "Hash: %s\n" "$hash"
# printf "Expires: %s\n" "$expires"
#
links_url=$(curl -s "https://playerwatchlm09.xyz/api/v1/security/episode-access?id_episode=${id}&hash=${hash}&expires=${expires}"|tr "{|}|," "\n")
# printf "Links URL: %s\n" "$links_url"
#
low_quality="$(printf "%s" "$links_url"|sed -En 's_"480":"([^"]*)"_\1_p'))"
medium_quality="$(printf "%s" "$links_url"|sed -En 's_"720":"([^"]*)"_\1_p')"
high_quality="$(printf "%s" "$links_url"|sed -En 's_"1080":"([^"]*)"_\1_p')"
# printf "Low quality: %s\n" "$low_quality"
# printf "Medium quality: %s\n" "$medium_quality"
# printf "High quality: %s\n" "$high_quality"

subs=$(printf "%s" "$links_url"|sed -En 's_"file":"([^"]*)"_\1_p'|grep -v _|sed -e "s_^_${base}_g"|sed 's/:/\\:/g'|tr "\n" ":"|sed 's/:$//')
# printf "Subtitles: %s\n" "$subs"

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


