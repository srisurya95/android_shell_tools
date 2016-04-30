#!/usr/bin/env bash
source /media/adriandc/AndroidDev/Server/Vars.rc;

# Register Terminal
echo $PPID >$ScriptTerminal;
JobTimeStart=$(date +%s);

# JobsNames
jobs=(huashancm121 huashancm130 huashanadds huashanaicp \
      lxanzu130    lxdevs130    lxtest130   lxrelease130);

# Devices
DevicesLegacyXperia=(anzu  haida  coconut urushi  smultron \
                     mango hallon iyokan  satsuma zeus phoenix);

# Launch Build
case $1 in
     ${jobs[0]})  $ServerDir/HuashanCM121.sh >$ScriptsJob 2>&1;;
     ${jobs[1]})  $ServerDir/HuashanCM130.sh >$ScriptsJob 2>&1;;
     ${jobs[2]})  $ServerDir/HuashanAddons.sh >$ScriptsJob 2>&1;;
     ${jobs[3]})  $ServerDir/HuashanAICP.sh >$ScriptsJob 2>&1;;
     ${jobs[4]})  $ServerDir/LegacyXperia130.sh "" "anzu" >$ScriptsJob 2>&1;;
     ${jobs[5]})  $ServerDir/LegacyXperia130.sh "synconly,legacyxperia" >$ScriptsJob 2>&1;&
     ${jobs[6]})  for device in ${DevicesLegacyXperia[@]}; do
                    $ServerDir/LegacyXperia130.sh "nosync,rmoutdevice" "$device" >>$ScriptsJob 2>&1;
                  done;;
     ${jobs[7]})  $ServerDir/LegacyXperia130.sh "synconly,legacyxperia" >$ScriptsJob 2>&1;
                  for device in ${DevicesLegacyXperia[@]}; do
                    $ServerDir/LegacyXperia130.sh "nosync,rmoutdevice,release" "$device" >>$ScriptsJob 2>&1;
                  done;;
     *) echo "";
        echo " Error: No Job selected from [${jobs[*]}]";
        echo " Error: No Job selected from [${jobs[*]}]" >$ScriptsJob 2>&1;;
esac;

JobTimeDiff=$(($(date +%s)-$JobTimeStart));
echo "";
echo " [ Job '$1' done in $JobTimeDiff secs ]";
echo "";

# Scheduled Job (crontab -e)
#
# sudo apt-get update && sudo apt-get install gnome-schedule
#
# 30 06 * * * /media/adriandc/AndroidDev/Server/Job.sh 1
# 30 05 * * * /media/adriandc/AndroidDev/Server/Reboot.sh
