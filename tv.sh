#!/bin/sh
# FOR NOW THIS ONLY WORKS WITH TV SHOWS AND THE SID AND SECRET ARE HARDCODED

base="https://lookmovie2.to"

[ -z "$*" ] && printf "Enter a TV Show name: " && read -r query || query=$*
query=$(printf "%s" "$query"|tr " " "%20")
show_page="$base"$(curl -s "https://lookmovie2.to/shows/search/?q=$query"|tr -d "\n"|grep -Eo '<h6>.+?</a>'|
  sed -En 's_.*href="([^"]*)">(.*)</a>_\1\2_p'|fzf --height=8 --with-nth 2..|cut -d' ' -f1)

###### CAPTCHA STUFF ######

# recaptcha_link=$(curl -s "$show_page"|grep recaptcha|sed -En 's_.*script src="([^"]*)".*_\1_p')
# v=$(curl -s "$recaptcha_link"|
#   sed -En "s_.*po.src='.*/(.*)/recaptcha.*_\1_p")
# k="6LdPO70aAAAAAPLTFBiLkiyTlzco6VNnD0Y6jP3b"

# curl -s "https://www.google.com/recaptcha/api2/anchor?ar=1&k=${k}&hl=en&v=${v}&size=invisible&cb=j34k5o3kbxzl"

###### CAPTCHA STUFF ######

sid="o0d77am4jdpgd10h013pehetm4"
sec="11080afefff5790eb362a86bfb714e2e4e111b8a"
build_url=$(printf "%s" "$show_page?&sid=${sid}&sec=${sec}"|
  sed 's_.*view/_https://playerwatchlm10.xyz/shows/play/_g')
url=$(curl -sL "$build_url")

# get the last season of the show
last_season=$(printf "%s" "$url"|tail -r|grep -m1 "season: '"|
  sed -En "s@.*season: '([0-9]*)'.*@\1@p")

# TODO: simplify this
# if there is only one season, then set that as the season, else ask the user to choose a season
# if the user input is empty, then set the season to the last season
if [ "$last_season" = "1" ]; then
  season="1"
else
  printf "Choose a season between 1 and %s: " "$last_season" && read -r season
  [ -z "$season" ] && season="$last_season"
fi

# depending on the season, get the last episode of the season
if [ "$season" -eq "$last_season" ]; then
  last_episode=$(printf "%s" "$url"|tail -r|grep -m1 "episode: '"|
    sed -En "s@.*episode: '([0-9]*)'.*@\1@p")
else
  last_episode=$(printf "%s" "$url"|tail -r|grep -m1 -A5 "season: '$season'"|
    sed -En "s@.*episode: '([0-9]*)'.*@\1@p")
fi

# TODO: simplify this
# if there is only one episode, then set that as the episode, else ask the user to choose an episode
# if the user input is empty, then set the episode to the last episode
if [ "$last_episode" = "1" ]; then
  episode="1"
else
  printf "Choose an episode between 1 and %s: " "$last_episode" && read -r episode
  [ -z "$episode" ] && episode=$last_episode
fi

printf "You chose season %s, episode %s\n" "$season" "$episode"

id=$(printf "%s" "$url"|tr -d "\n"|tr -d "[:space:]"|sed -En "s@.*episode:'$episode',id_episode:([0-9]*),season:'$season'.*@\1@p")
hash=$(printf "%s" "$url"|sed -En "s_.*hash: '([^']*)'.*_\1_p")
expires=$(printf "%s" "$url"|grep "expires"|sed 's/[^0-9]//g')
links_url=$(curl -s "https://playerwatchlm09.xyz/api/v1/security/episode-access?id_episode=${id}&hash=${hash}&expires=${expires}"|tr "{|}|," "\n")

low_quality="$(printf "%s" "$links_url"|sed -En 's_"480":"([^"]*)"_\1_p'))"
medium_quality="$(printf "%s" "$links_url"|sed -En 's_"720":"([^"]*)"_\1_p')"
high_quality="$(printf "%s" "$links_url"|sed -En 's_"1080":"([^"]*)"_\1_p')"

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

