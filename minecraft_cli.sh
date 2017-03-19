#!/bin/bash
# /usr/local/bin/
# 
### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs screen-cleanup
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    Minecraft server
# Description:    Starts the minecraft server
### END INIT INFO

#Settings
SERVICE='minecraft_server.1.11.2.jar'
SCREENNAME='minecraft'
OPTIONS='nogui'
USERNAME='minecraft'
WORLD='world'
MCPATH='/srv/minecraft-server'
BACKUPPATH='/srv/minecraft-server/world_backup'
#MAXHEAP=2048
#MINHEAP=1024
#HISTORY=1024
#CPU_COUNT=1
#INVOCATION="java -Xmx${MAXHEAP}M -Xms${MINHEAP}M -XX:+UseConcMarkSweepGC \
#-XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts \
#-jar $SERVICE $OPTIONS" 

ME=`whoami`
as_user() {
  if [ "$ME" = "$USERNAME" ] ; then
    bash -c "$1"
  else
    su - "$USERNAME" -c "$1"
  fi
}

# mc_start() {
#   if  pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
#     echo "$SERVICE is already running!"
#   else
#     echo "Starting $SERVICE..."
#     cd $MCPATH
#     as_user "cd $MCPATH && screen -h $HISTORY -dmS ${SCREENNAME} $INVOCATION"
#     sleep 7
#     if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
#       echo "$SERVICE is now running."
#     else
#       echo "Error! Could not start $SERVICE!"
#     fi
#   fi
# }

mc_saveoff() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
    echo "$SERVICE is running... suspending saves"
   as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER BACKUP STARTING. Server going readonly...\"\015'"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-off\"\015'"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-all\"\015'"
    sync
    sleep 10
  else
    echo "$SERVICE is not running. Not suspending saves."
  fi
}

mc_saveon() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
    echo "$SERVICE is running... re-enabling saves"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-on\"\015'"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
  else
    echo "$SERVICE is not running. Not resuming saves."
  fi
}

# mc_stop() {
#   if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
#     echo "Stopping $SERVICE"
#     as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
#     as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-all\"\015'"
#     sleep 10
#     as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"stop\"\015'"
#     sleep 7
#   else
#     echo "$SERVICE was not running."
#   fi
#   if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
#     echo "Error! $SERVICE could not be stopped."
#   else
#     echo "$SERVICE is stopped."
#   fi
# }

# mc_update() {
#   if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
#     echo "$SERVICE is running! Will not start update."
#   else
#     as_user "cd $MCPATH && wget -q -O $MCPATH/versions --no-check-certificate https://launchermeta.mojang.com/mc/game/version_manifest.json"
#     if [ "$1" == "snapshot" ] ; then
#       JSONVERSION=`cd $MCPATH && cat versions | python -c "exec(\"import json,sys\nobj=json.load(sys.stdin)\nversion=obj['latest']['snapshot']\nfor v in obj['versions']:\n   if v['id']==version:\n    print(v['url'])\")"`
#     else
#       JSONVERSION=`cd $MCPATH && cat versions | python -c "exec(\"import json,sys\nobj=json.load(sys.stdin)\nversion=obj['latest']['release']\nfor v in obj['versions']:\n   if v['id']==version:\n    print(v['url'])\")"`
#     fi
#     as_user "cd $MCPATH && wget -q -O $MCPATH/versions --no-check-certificate $JSONVERSION"
#     MC_SERVER_URL=`cd $MCPATH && cat versions | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["downloads"]["server"]["url"])'`
#     as_user "rm $MCPATH/versions"
#     as_user "cd $MCPATH && wget -q -O $MCPATH/minecraft_server.jar.update --no-check-certificate $MC_SERVER_URL"
#     if [ -f $MCPATH/minecraft_server.jar.update ] ; then
#       if `diff $MCPATH/$SERVICE $MCPATH/minecraft_server.jar.update >/dev/null` ; then
#         echo "You are already running the latest version of $SERVICE."
#       else
#         as_user "mv $MCPATH/minecraft_server.jar.update $MCPATH/$SERVICE"
#         echo "Minecraft successfully updated."
#       fi
#     else
#       echo "Minecraft update could not be downloaded."
#     fi
#   fi
# }

mc_backup() {
   mc_saveoff
   
   NOW=`date "+%Y-%m-%d_%Hh%M"`
   BACKUP_FILE="$BACKUPPATH/${WORLD}_${NOW}.tar"
   echo "Backing up minecraft world..."
   #as_user "cd $MCPATH && cp -r $WORLD $BACKUPPATH/${WORLD}_`date "+%Y.%m.%d_%H.%M"`"
   as_user "tar -C \"$MCPATH\" -cf \"$BACKUP_FILE\" $WORLD"

   echo "Backing up $SERVICE"
   as_user "tar -C \"$MCPATH\" -rf \"$BACKUP_FILE\" $SERVICE"
   #as_user "cp \"$MCPATH/$SERVICE\" \"$BACKUPPATH/minecraft_server_${NOW}.jar\""

   mc_saveon

   echo "Compressing backup..."
   as_user "gzip -f \"$BACKUP_FILE\""
   echo "Done."
}

mc_command() {
  command="$1";
  if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
    pre_log_len=`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`
    echo "$SERVICE is running... executing command"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"$command\"\015'"
    sleep .1 # assumes that the command will run and print to the log file in less than .1 seconds
    # print output
    tail -n $((`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`-$pre_log_len)) "$MCPATH/logs/latest.log"
  fi
}

#Start-Stop here
case "$1" in
  backup)
    mc_backup
    ;;
  status)
    if pgrep -u $USERNAME -f $SERVICE > /dev/null ; then
      echo "$SERVICE is running."
    else
      echo "$SERVICE is not running."
    fi
    ;;
  command)
    if [ $# -gt 1 ] ; then
      shift
      mc_command "$*"
    else
      echo "Must specify server command (try 'help'?)"
    fi
    ;;

  *)
  echo "Usage: $0 {backup|status|command \"server command\"}"
  exit 1
  ;;
esac

exit 0
