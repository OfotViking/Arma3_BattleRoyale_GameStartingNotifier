#!/bin/bash

# exclude US, show only Altis.HC and Bozcaada.HC only SOLO 
grepx='US'
grep1='Altis.HC|Bozcaada.HC'
grep2='SOLO'

green=$(tput setaf 2)
normal=$(tput sgr0)

while true; do
# loop start

grab=$(wget -qO - http://status.battleroyalegames.com/)
servers=$(echo "$grab" | grep server_name | grep -v OFFLINE | egrep -v $grepx | egrep $grep1 | egrep $grep2 | sed 's/  /_/g' | sed 's/ /_/g' | sed 's/>/> /g' | sed -e 's/<[^>]*>//g' | sed 's/&nbsp;//g' | sed 's/_Battle_Royale_._battleroyalegames.com//g' | sed 's/   / /g' | sed 's/  / /g' | sed 's/ //' )

# use the same refreshinterval as on website
refreshtime=$(echo "$grab" | grep JavaScript:timedRefresh | cut -d"\"" -f 2 | cut -d"(" -f2 | cut -d"\"" -f 2 | cut -d")" -f1) 

# add 60 seconds if all servers empty
refreshseconds=$(expr $refreshtime / 1000 + 60) 

clear

echo "Arma 3 Battle Royale server status/notifier/logger"
echo " "

while read -r line; do
  name=$(echo -n "$line" | cut -d" " -f1,2,3 | cut -d"_" -f1 | sed 's/ //g')
  id=$(echo -n "$line" | cut -d" " -f1,2,3 | md5sum | cut -d " " -f1)
  ip=$(echo -n "$line" | cut -d" " -f5)
  status=$(echo -n "$line" | cut -d" " -f4)
  players=$(echo -n "$line" | cut -d" " -f6 | cut -d"/" -f1)
  date=$(cat /tmp/date$id)
  

  
  date2=$(echo $date | cut -d" " -f2-4)
  
  printf "%-27s %s" " $name" \|
  if [ $status = SERVER_OPEN ] && (( $players > 1 )); then
    #status_color="\e[32m$status\e[0m"
    #printf "%-17s %s"  '\e[1;34m%-6s\e[m' " $status" \|
	printf "${green}"
    printf "%-17s %s" " $status"
	printf "${normal}|"
  else
    printf "%-17s %s" " $status" \|
  fi
  
  printf "%-15s %s" " $date2" \|
  printf "%-3s %s" " $players" \|
  printf "%-21s %s" " $ip" \|
  
  touch /tmp/notified$id
  touch /tmp/date$id
  touch /tmp/logged$id
  
  if [ $status = SERVER_OPEN ] && [ "$(cat /tmp/notified$id)" != "yes" ] && (( $players > 16 )); then
  echo -n  " New server filling up, notification sendt"
  echo -n $'\a' #beep
  refreshseconds=$(expr $refreshtime / 1000)
  #notify-command here
  ./GrowlNotify --finished "$name"
  echo -n "yes" > /tmp/notified"$id"
  fi
  if [ $status = SERVER_OPEN ] && [ "$(cat /tmp/notified$id)" = "yes" ] && (( $players > 17 )); then
  echo -n  " Server filling up, join NOW!"
  refreshseconds=$(expr $refreshtime / 1000)
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
  refreshseconds=$(expr $refreshtime / 1000)
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
