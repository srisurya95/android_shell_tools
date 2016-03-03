#!/bin/bash
ScriptDir=$PWD;
ScriptsDir=$ScriptDir;
FullTimeStart=$(date +%s);
BuildMode="$2";

# Android Selection
function android_selection() { source ./android_choose_rom.sh 4 n n; }
android_selection;

# Development Scripts
source $ScriptsDir/android_set_variables.rc;

# Sources Sync
if [[ ! "$BuildMode" =~ "test" && ! "$BuildMode" =~ "nosync" ]]; then
  echo "";
  echo " [ Syncing $PhoneName repositories ]";
  echo "";
  cd $AndroidDir/;
  repo forall -c 'echo "Cleaning project ${REPO_PROJECT}"; \
                  git rebase --abort >/dev/null 2>&1; \
                  git stash -u >/dev/null 2>&1; \
                  git reset --hard HEAD >/dev/null 2>&1;';
  repo sync --current-branch --detach --force-broken --force-sync;
  source ./build/envsetup.sh;

  croot;
  cd ./build/;
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_build;
  git cherry-pick ee0b6151e2989600131ed4ccc1eaf2682826b2a1;
  git cherry-pick dcf7d09d7bab319e860b8bcb9d506cf9834948de;
  git cherry-pick a331253dd2f538c642899bc4b49c54185c9ef770;

  croot;
  cd ./system/core/;
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_system_core;
  git cherry-pick a57098bb9ee2a3d1beb93bb52fa0873f53e0625a;
  git cherry-pick 75bf203c6b35e965ff9ee7a0bc85b3b5fb08bf80;
  git cherry-pick 0951fb068e73ae448a1eeea12a0f1d334137b876;

  croot;
  cd ./frameworks/opt/telephony/;
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_frameworks_opt_telephony;
  git cherry-pick a5fa7a9447a4f327a674957db9ea2f2ccda33c83;
  git cherry-pick 822a8d90f93aa42d9e1947e68c1662d21cf9eefd;
  git cherry-pick 565be597909135738fc5f896daf610bae2f9889d;
  git cherry-pick bb319c30d734de272e6259edf483e39265bf7cb5;
  git cherry-pick 3277511ff4833e1262a15647c5bc23c039eff9f8;

  croot;
  cd ./hardware/ril-caf/;
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_hardware_ril;
  git cherry-pick a5fa7a9447a4f327a674957db9ea2f2ccda33c83;
  git cherry-pick 822a8d90f93aa42d9e1947e68c1662d21cf9eefd;
  git cherry-pick 565be597909135738fc5f896daf610bae2f9889d;
  git cherry-pick bb319c30d734de272e6259edf483e39265bf7cb5;
  git cherry-pick 3277511ff4833e1262a15647c5bc23c039eff9f8;

  sed -i "s/\(ALOGV(\"message received msg=%d, ext1=%d, ext2=%d, obj=\)%x\(\",\)/\1%p\2/g" "frameworks/base/cmds/bootanimation/BootAnimation.cpp";
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
  source $ScriptsDir/android_brunch.sh "automatic" "$BuildMode,otapackage";

  # ROM Successful
  if [ -f "$AndroidResult" ]; then
    BuildSuccess="true";
  fi;

  # ROM Upload
  if [[ ! "$BuildMode" =~ "local" ]]; then
    cd $ScriptsDir/;
    if [[ ! "$BuildMode" =~ "test" ]]; then
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "Huashan/AOSP-CAF-6.0" "automatic";
    else
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "Development" "automatic";
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
if [ -z "$1" ]; then
  read key;
fi;
