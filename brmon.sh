#!/bin/bash

# config (this should show everything)
exclude='nothing'
include1='HC|REG'
include2='Altis|Bozcaada|Stratis|Tanoa|Wake'

#### exapmle 1 ( Exclude US, Show only HC + RANKED)
# exclude='US'
# include1='RANKED'
# include2='HC'

#### exapmle 2 ( Exclude US, Show only HC + Ranked and Tanoa)
# exclude='US'
# include1='HC'
# include2='RANKED|Tanoa'

#### exapmle 3 ( Exclude US, Show only HC-Ranked and Regular-Wake and HC-Wake/Tanoa)
# exclude='US'
# include1='HC|REG\]\[Wake'
# include2='RANKED|Tanoa|Wake'

green=$(tput setaf 2)
orange=$(tput setaf 172)
normal=$(tput sgr0)

while true; do
# loop start

screen=$(screen -ls | grep tached)
if [[ $screen == *"Attached"* ]]; then

grab=$(wget -qO - http://status.battleroyalegames.com/)
servers=$(echo "$grab" | grep server_name | egrep -v 'OFFLINE|UNKNOWN' | egrep -v "$exclude" | sed 's/&nbsp;//g' | sed -e 's/<[^>]*b>//g' | sed 's/  //g' | sed 's/ //g' | sed -e 's/<[^>]*>/ /g' | sed 's/battleroyalegames.com//g'| egrep "$include1" | egrep "$include2" | sed 's/SERVEROPEN/SERVER_OPEN/g' | sed 's/GAMEINPROGRESS/GAME_IN_PROGRESS/g' | sed 's/OPENINGSOON/OPENING_SOON/g' |sort)


# use the same refreshinterval as on website
refreshtime=$(echo "$grab" | grep JavaScript:timedRefresh | cut -d"\"" -f 2 | cut -d"(" -f2 | cut -d"\"" -f 2 | cut -d")" -f1) 

# add 60 seconds if all servers empty
refreshseconds=$(expr $refreshtime / 1000 + 60) 

clear

#echo "####"
#echo "$servers"
#echo "####"

echo "Arma 3 Battle Royale server status/notifier/logger"
echo " "

while read -r line; do
  name=$(echo -n "$line" | awk '{print $1}')
  id=$(echo -n "$line" | awk '{print $1 $3}' | md5sum | cut -d " " -f1)
  ip=$(echo -n "$line" | awk '{print $3}')
  status=$(echo -n "$line" | awk '{print $2}')
  players=$(echo -n "$line" | awk '{print $4}' | cut -d"/" -f1)
  date=$(cat /tmp/date$id)
  

  
  date2=$(echo $date | cut -d" " -f2-4)
  
  if [ $status = "SERVER_OPEN" ] && (( $players > 1 )); then
    #status_color="\e[32m$status\e[0m"
    #printf "%-17s %s"  '\e[1;34m%-6s\e[m' " $status" \|
	  printf "${green}"
    printf "%-30s %s" " $name"
	  printf "${normal}|"
  else
    printf "%-30s %s" " $name" \|
  fi
  
  printf "%-3s %s" " $players" \|  
  
  if [ $status = "SERVER_OPEN" ] && (( $players > 1 )); then
    #status_color="\e[32m$status\e[0m"
    #printf "%-17s %s"  '\e[1;34m%-6s\e[m' " $status" \|
	  printf "${green}"
    printf "%-17s %s" " $status"
	  printf "${normal}|"
  elif [ $status = "GAME_IN_PROGRESS" ] && (( $players < 4 )); then
	  printf "${orange}"
    printf "%-17s %s" " $status"
	  printf "${normal}|"
  elif [ $status = "OPENING_SOON" ] ; then
	  printf "${orange}"
    printf "%-17s %s" " $status"
	  printf "${normal}|"
  else
    printf "%-17s %s" " $status" \|
  fi
  
  printf "%-16s %s" " $date2" \|
  
  printf "%-21s %s" " $ip" \|
  
  touch /tmp/notified$id
  touch /tmp/date$id
  touch /tmp/logged$id
  
  if [ $status = "SERVER_OPEN" ] && [ "$(cat /tmp/notified$id)" != "yes" ] && (( $players > 16 )); then
  echo -n  " *"
  #echo -n $'\a' #beep
  refreshseconds=$(expr $refreshtime / 1000)
  #notify-command here
  #./GrowlNotify --finished "$name"
  echo -n "yes" > /tmp/notified"$id"
  fi
  if [ $status = "SERVER_OPEN" ] && [ "$(cat /tmp/notified$id)" = "yes" ] && (( $players > 17 )); then
  echo -n  " Server filling up, join NOW!"
  refreshseconds=$(expr $refreshtime / 1000)
  #echo $'\a' #beep
  fi
  if [ $status = "GAME_IN_PROGRESS" ] && [ "$(cat /tmp/notified$id)" != "no" ]; then
  echo -n " Just started!"
  echo -n "no" > /tmp/notified"$id"
  fi
  if [ $status = "GAME_IN_PROGRESS" ] && (( $players < 4 )); then
  echo -n " Finishing soon!"
  echo -n $(TZ=Europe/London date) > /tmp/date"$id"
  #date +%Y%m%d-%H%M%S
  date=$(cat /tmp/date$id)
  echo -n "no" > /tmp/logged"$id"
  refreshseconds=$(expr $refreshtime / 1000)
  fi
  if [ $status != "GAME_IN_PROGRESS" ] && [ "$(cat /tmp/logged$id)" != "yes" ]; then
  echo $name \| $date >> log.txt
  echo -n "yes" > /tmp/logged"$id"
  fi
  echo " "

done <<< "$servers"
echo " "
echo "refresh in $refreshseconds seconds ..."
sleep $refreshseconds

# loop end

else
sleep 120
fi
done
