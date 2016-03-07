#!/bin/bash
source /media/adriandc/AndroidDev/Server/Vars.rc;

# Phone Name
if [ ! -z "$2" ]; then
  export PhoneName="$2";
else
  export PhoneName="anzu";
fi;
BuildLog="$ScriptsLog.$PhoneName.CM110.log";

# Launch Mode
BuildMode="manual";
if [ ! -z "$1" ]; then
  BuildMode="$1";
fi;

# Compilation Script
cd $ScriptsDir;
source ./android_auto_legacyxperia.sh "automatic" "$BuildMode,cm-11.0" 2>&1 | tee -a "$BuildLog";

# Update script logs
source $ServerDir/LogsSync.sh;

# PushBullet Notification
BuildSuccess=$(grep -a "make completed successfully" $BuildLog | uniq);
if [ ! -z "$BuildSuccess" ]; then
  PushBulletComment="CM-11.0 ROM for $PhoneName ready";
else
  PushBulletComment="CM-11.0 ROM for $PhoneName failed";
fi;
notify-send "$PushBulletComment";
source $ServerDir/PushBullet.sh;

# CronTab End
if [ -z "$1" ]; then
  read key;
fi;
