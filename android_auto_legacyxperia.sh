#!/bin/bash
ScriptDir=$PWD;
ScriptsDir=$ScriptDir;
FullTimeStart=$(date +%s);
BuildMode="$1";

# Android Selection
if [[ "$BuildMode" =~ "cm-11.0" ]]; then
  BuildBranch="cm-11.0";
  function android_selection() { source ./android_choose_rom.sh 9 n n; }
elif [[ "$BuildMode" =~ "cm-12.1" ]]; then
  BuildBranch="cm-12.1";
  function android_selection() { source ./android_choose_rom.sh 8 n n; }
else
  BuildBranch="cm-13.0";
  function android_selection() { source ./android_choose_rom.sh 7 n n; }
fi;
android_selection;

# Development Scripts
source $ScriptsDir/android_set_variables.rc;
source $BashDir/android_legacyxperia.rc;

# Dependencies Deletion
if ls "$AndroidDir/device/"*"/$PhoneName/"*.dependencies 1> /dev/null 2>&1; then
  rm "$AndroidDir/device/"*"/$PhoneName/"*.dependencies;
fi;

# Sources Sync
if [[ ! "$BuildMode" =~ "test" && ! "$BuildMode" =~ "nosync" ]]; then
  echo "";
  echo " [ Syncing $PhoneName repositories ]";
  echo "";
  cd $AndroidDir/;
  reposalx $BuildBranch "$BuildMode";
fi;


# System Output Cleaning
if [[ "$BuildMode" =~ "clean" ]]; then
  echo "";
  echo " [ Cleaning outputs ]";
  echo "";
  cd $AndroidDir/;
  make clean;
elif [[ ! "$BuildMode" =~ "test" || "$BuildMode" =~ "wipe" ]] && [ -d "$OutDir/system" ]; then
  echo "";
  echo " [ System - Wiping /system output ]";
  rm -rf "$OutDir/system";
  echo "";
  echo "Output folder '/system' deleted";
  echo "";
fi;

# ROM Build
BuildSuccess="";
if [[ ! "$BuildMode" =~ "synconly" ]]; then
  cd $ScriptsDir/;
  android_selection;
  source $ScriptsDir/android_brunch.sh "automatic,$BuildMode";

  # ROM Successful
  if [ ! -z "$AndroidResult" ] && [ -f "$AndroidResult" ]; then
    BuildSuccess="true";
  fi;

  # ROM Upload
  if [[ ! "$BuildMode" =~ "local" ]]; then
    cd $ScriptsDir/;
    if [[ "$BuildMode" =~ "release" ]]; then
      md5sum $AndroidResult >$AndroidResult.md5sum;
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "$PhoneName/$BuildBranch" "legacyxperia";
      source $ScriptsDir/android_server_upload.sh "$AndroidResult.md5sum" "$PhoneName/$BuildBranch" "legacyxperia";
    elif [[ ! "$BuildMode" =~ "test" ]]; then
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "LegacyXperia/$PhoneName/$BuildBranch";
    else
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "Development";
    fi;
    if [ ! -z "$BuildSuccess" ] && [[ "$BuildMode" =~ "rmoutdevice" ]] && [ -d "$OutDir" ]; then
      echo "";
      echo " [ $PhoneName - Removing output folder ]";
      echo "";
      TargetFile=$(basename "$AndroidResult");
      if [ -f "$TargetDir/$TargetFile" ]; then
        rm -f "$TargetDir/$TargetFile";
      fi;
      cp "$AndroidResult" "$TargetDir/$TargetFile";
      cp "$AndroidResult.md5sum" "$TargetDir/$TargetFile.md5sum";
      rm -rf "$OutDir/";
    fi;
  fi;
else
  BuildSuccess="true";
fi;

# Build Finished
FullTimeDiff=$(($(date +%s)-$FullTimeStart));
echo "";
if [ ! -z "$BuildSuccess" ]; then
  echo " [ Build : Success in $FullTimeDiff secs ]";
else
  echo " [ Build : Fail in $FullTimeDiff secs ]";
fi;
echo "";
