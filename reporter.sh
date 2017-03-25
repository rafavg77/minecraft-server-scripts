#!/bin/bash


players=$(/usr/local/bin/minecraft_cli command list | awk "NR==3 {print $3}" | cut -d ":" -f 4)

if [ -z "$players" ]
then
	/usr/local/bin/telegram_bot_players "$players"
	#echo "No players Connected"
else 
	#/usr/local/bin/telegram_bot "$players"
	echo "No players Connected"
fi
