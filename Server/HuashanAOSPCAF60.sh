#!/bin/bash
source /media/adriandc/AndroidDev/Server/Vars.rc;

# Phone Name
if [ ! -z "$2" ]; then
  export PhoneName="$2";
else
  export PhoneName="huashan";
fi;
BuildLog="$ScriptsLog.$PhoneName.AOSPCAFM.log";

# Launch Mode
BuildMode="manual";
if [ ! -z "$1" ]; then
  BuildMode="$1";
fi;

# Compilation Script
cd $ScriptsDir;
source ./android_auto_huashan_aospcaf60.sh "$BuildMode" 2>&1 | tee "$BuildLog";

# Update script logs
source $ServerDir/LogsSync.sh;

# PushBullet Notification
BuildSuccess=$(grep -a "make completed successfully" $BuildLog | uniq);
if [ ! -z "$BuildSuccess" ]; then
  PushBulletComment="AOSP-CAF M ROM for $PhoneName ready";
else
  PushBulletComment="AOSP-CAF M ROM for $PhoneName failed";
fi;
notify-send "$PushBulletComment";
source $ServerDir/PushBullet.sh;
