#!/bin/bash
ScriptDir=$PWD;
ScriptsDir=$ScriptDir;
FullTimeStart=$(date +%s);
BuildMode="$1";

# Android Selection
function android_selection() { source ./android_choose_rom.sh 1 n n; }
android_selection;

# Development Scripts
source $ScriptsDir/android_set_variables.rc;


# Dependencies Deletion
if ls "$AndroidDir/device/"*"/$PhoneName/"*.dependencies 1> /dev/null 2>&1; then
  rm "$AndroidDir/device/"*"/$PhoneName/"*.dependencies;
fi;

# Sources Updates
if [[ ! "$BuildMode" =~ "test" && ! "$BuildMode" =~ "nosync" ]]; then
  cd $ScriptsDir/;
fi;














# System Output Cleaning
if [[ "$BuildMode" =~ "clean" ]]; then
  echo "";
  echo " [ Cleaning outputs ]";
  echo "";
  cd $AndroidDir/;
  make clean;
elif [[ ! "$BuildMode" =~ "nowipe" ]] && [[ ! "$BuildMode" =~ "test" || "$BuildMode" =~ "wipe" ]] && [ ! -z "$OutDir" ]; then
  echo "";
  echo " [ System - Wiping /system output ]";
  rm -rf "$OutDir/combinedroot";
  rm -rf "$OutDir/data";
  rm -rf "$OutDir/recovery";
  rm -rf "$OutDir/root";
  rm -rf "$OutDir/system";
  rm -rf "$OutDir/utilities";
  rm -rf "$OutDir/boot"*;
  rm -rf "$OutDir/combined"*;
  rm -rf "$OutDir/kernel";
  rm -rf "$OutDir/ramdisk"*;
  rm -rf "$OutDir/recovery"*;
  rm -rf "$OutDir/system"*;
  echo "";
  echo "Output folder '/system' deleted";
  echo "";
fi;

# Sources Sync
if [[ ! "$BuildMode" =~ "test" && ! "$BuildMode" =~ "nosync" ]]; then
  echo "";
  echo " [ Syncing $PhoneName repositories ]";
  echo "";
  cd $AndroidDir/;
  if [[ "$BuildMode" =~ "clean" ]] || [[ "$BuildMode" =~ "safe" ]]; then
    repo forall -c 'echo "Cleaning project ${REPO_PROJECT}"; \
                    git rebase --abort >/dev/null 2>&1; \
                    git stash -u >/dev/null 2>&1; \
                    git reset --hard HEAD >/dev/null 2>&1;';
  fi;
  repo sync --current-branch --detach --force-broken --force-sync;

  # Additional changes
  # cd $AndroidDir/packages/apps/Mms/;
  # git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_packages_apps_Mms-caf refs/changes/75/129975/5 && git cherry-pick FETCH_HEAD;
fi;

# ROM Build
BuildSuccess="";
if [[ ! "$BuildMode" =~ "synconly" ]]; then
  cd $ScriptsDir/;
  android_selection;
  if [[ "$BuildMode" =~ "kernel" ]]; then
    source $ScriptsDir/android_make_kernel.sh "release" "cm-12.1-";
  else
    source $ScriptsDir/android_brunch.sh "automatic,$BuildMode";
  fi;

  # ROM Successful
  if [ ! -z "$AndroidResult" ] && [ -f "$AndroidResult" ]; then
    BuildSuccess="true";
  fi;

  # ROM Upload
  if [[ ! "$BuildMode" =~ "local" ]]; then
    cd $ScriptsDir/;
    if [[ ! "$BuildMode" =~ "test" ]]; then
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "Huashan/CyanogenMod-12.1";
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
