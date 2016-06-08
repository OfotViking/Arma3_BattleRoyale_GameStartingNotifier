#!/bin/bash

grep1='EU|UK|DE|FR|US'
grep2='Hardcore|Regular'
#grep2='Hardcore|Squads|WAKE|Stratis\|Hardcore'

while true; do
# loop start

grab=$(wget -qO - http://battleroyale.gamingdeluxe.co.uk/status/)
servers=$(echo "$grab" | grep server_name | grep -v OFFLINE | egrep $grep1 | egrep $grep2 | sed 's/  /_/g' | sed 's/ /_/g' | sed 's/>/> /g' | sed -e 's/<[^>]*>//g' | sed 's/&nbsp;//g' | sed 's/   / /g' | sed 's/  / /g' | sed 's/ //' | sed 's/_ /_/' | rev | cut -d" " -f 3-10 | rev)

refreshtime=$(echo "$grab" | grep JavaScript:timedRefresh | cut -d"\"" -f 2 | cut -d"(" -f2 | cut -d"\"" -f 2 | cut -d")" -f1)
refreshseconds=$(expr $refreshtime / 1000 + 30)

clear

echo "Arma 3 Battle Royale server status"
echo " "

while read -r line; do
  name=$(echo -n "$line" | cut -d" " -f1,2 | cut -d"_" -f1)
  id=$(echo -n "$line" | cut -d" " -f1,2 | md5sum | cut -d " " -f1)
  ip=$(echo -n "$line" | cut -d" " -f4)
  status=$(echo -n "$line" | cut -d" " -f3)
  players=$(echo -n "$line" | cut -d" " -f5 | cut -d"/" -f1)
  date=$(cat /tmp/date$id)
  echo -n $name \| $status \| $date \| $players \| $ip \|
  
  touch /tmp/notified$id
  touch /tmp/date$id
  touch /tmp/logged$id
  
  if [ $status = SERVER_OPEN ] && [ "$(cat /tmp/notified$id)" != "yes" ] && (( $players > 16 )); then
  echo -n  " New server filling up, notification sendt"
  echo -n $'\a' #beep
  #notify-command here
  #./GrowlNotify --finished "$name"
  echo -n "yes" > /tmp/notified"$id"
  fi
  if [ $status = SERVER_OPEN ] && [ "$(cat /tmp/notified$id)" = "yes" ] && (( $players > 17 )); then
  echo -n  " Server filling up, join NOW!"
  #echo $'\a' #beep
  fi
  if [ $status = GAME_IN_PROGRESS ] && [ "$(cat /tmp/notified$id)" != "no" ]; then
  echo -n " ! Just started"
  echo -n "no" > /tmp/notified"$id"
  fi
  if [ $status = GAME_IN_PROGRESS ] && (( $players < 4 )); then
  echo -n " ! Finishing soon"
  echo -n $(TZ=Europe/London date) > /tmp/date"$id"
  #date +%Y%m%d-%H%M%S
  date=$(cat /tmp/date$id)
  echo -n "no" > /tmp/logged"$id"
  refreshseconds=30
  fi
  if [ $status != GAME_IN_PROGRESS ] && [ "$(cat /tmp/logged$id)" != "yes" ]; then
  echo $name \| $date >> log.txt
  echo -n "yes" > /tmp/logged"$id"
  fi
  echo " "

done <<< "$servers"
echo " "
echo "refresh in $refreshseconds seconds ..."
sleep $refreshseconds

# loop end
done
