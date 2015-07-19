#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;
FilePath="system/priv-app/SystemUI/";
FileName="SystemUI.apk";

if [ -f $Target/$FileName ]; then rm $Target/$FileName; fi;
cd $AndroidDir/;

echo "";
echo " [ Making the requested libraries ]";
echo "";
source ./build/envsetup.sh;
croot;
breakfast $PhoneName;
mmm -j8 ./frameworks/base/packages/SystemUI/;

TimeDiff=$(($(date +%s)-$TimeStart));
if [ "$(ls -A $TargetDir)" ]; then
  cp $OutDir/$FilePath$FileName $TargetDir/$FileName;
fi;
echo "";
echo "  \"adb push $FileName /$FilePath$FileName\"";
echo "";

adbPush=1;
while [ $adbPush ]
do
  echo "";
  echo " [ Upload new library files - Recovery / USB / mount system ]";
  echo "";
  printf "  Press enter to continue...";
  read key;

  echo "";
  $ScriptDir/android_root_adb.sh;
  cd $OutDir/;
  adb push $FilePath$FileName /$FilePath$FileName;
  if [ $? == 0 ]; then adbPush=0;
  else continue; fi;

  echo "";
  echo " Rebooting...";
  sleep 5;
  adb reboot;

  echo "";
  echo " [ Done in $TimeDiff secs ]";
  echo "";
  read key;
done;
