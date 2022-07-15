#!/bin/sh
# FOR NOW THIS ONLY WORKS WITH MOVIES AND THE SID IS HARDCODED

base="https://lookmovie2.to"

[ -z "$*" ] && printf "Enter a Movie name: " && read -r query || query=$*
query=$(printf "%s" "$query"|tr " " "+")
show_page="$base"$(curl -s "https://lookmovie2.to/movies/search/?q=$query"|tr -d "\n"|grep -Eo '<h6>.+?</a>'|
  sed -En 's_.*href="([^"]*)">(.*)</a>_\1\2_p'|fzf --height=8 --with-nth 2..|cut -d' ' -f1)

sid="o0d77am4jdpgd10h013pehetm4"
build_url=$(printf "%s" "$show_page?&sid=${sid}"|
  sed 's_.*view/_https://playerwatchlm10.xyz/movies/play/_g')
url=$(curl -sL "$build_url")

id=$(printf "%s" "$url"|sed -En "s@.*id_movie: ([0-9]*).*@\1@p")
hash=$(printf "%s" "$url"|sed -En 's_.*hash: "([^"]*)".*_\1_p')
expires=$(printf "%s" "$url"|grep "expires"|sed 's/[^0-9]//g')
title=$(printf "%s" "$url"|sed -En "s_.*title: '([^']*)',.*_\1_p")
links_url=$(curl -s "https://playerwatchlm10.xyz/api/v1/security/movie-access?id_movie=${id}&hash=${hash}&expires=${expires}"|tr "{|}|," "\n")

low_quality="$(printf "%s" "$links_url"|sed -En 's_"480p":"([^"]*)"_\1_p'))"
medium_quality="$(printf "%s" "$links_url"|sed -En 's_"720p":"([^"]*)"_\1_p')"
high_quality="$(printf "%s" "$links_url"|sed -En 's_"1080p":"([^"]*)"_\1_p')"

# only the first 4 english subs, otherwise mpv will take forever to load
subs=$(printf "%s" "$links_url"|sed -En 's_"file":"([^"]*)"_\1_p'|grep -m4 "en"|
  sed -e "s_^_${base}_g" -e 's/:/\\:/g' -e 'H;1h;$!d;x;y/\n/:/' -e 's/:$//')

[ -z "$high_quality" ] && [ -z "$medium_quality" ] && [ -z "$low_quality" ] && printf "No links found\n" && exit 1
[ -z "$high_quality" ] && [ -z "$medium_quality" ] && mpv --sub-files="$subs" --force-media-title="$title" "$low_quality"
[ -z "$high_quality" ] && mpv --sub-files="$subs" --force-media-title="$title" "$medium_quality"
[ -n "$high_quality" ] && mpv --sub-files="$subs" --force-media-title="$title" "$high_quality"

