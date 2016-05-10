#!/bin/bash
ScriptDir=$PWD;
ScriptsDir=$ScriptDir;
FullTimeStart=$(date +%s);
BuildMode="$1";

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
  if [[ ! "$BuildMode" =~ "unsafe" ]]; then
    repo forall -c 'echo "Cleaning project ${REPO_PROJECT}"; \
                    git rebase --abort >/dev/null 2>&1; \
                    git stash -u >/dev/null 2>&1; \
                    git reset --hard HEAD >/dev/null 2>&1;';
  fi;
  repo sync -j8 --current-branch --detach -f --force-broken --force-sync -c --no-clone-bundle --no-tags;
  source ./build/envsetup.sh;

  croot;
  cd ./build/; echo "";
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_build;core/dynamic_binary.mk
  git cherry-pick ee0b6151e2989600131ed4ccc1eaf2682826b2a1; # [NEEDED] build: Disable relocation packing on recovery and utility executables

  croot;
  cd ./bionic; echo "";
  # [NEEDED] bionic: linker: Load shim libs *before* the self-linked libs
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_bionic refs/changes/02/132902/1 && git cherry-pick FETCH_HEAD;
  # [NEEDED] Add prlimit to LP32.
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_bionic refs/changes/96/135596/1 && git cherry-pick FETCH_HEAD;

  croot;
  cd ./system/core/; echo "";
  # [NEEDED] Healthd and charger commits
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_system_core;
  git cherry-pick a57098bb9ee2a3d1beb93bb52fa0873f53e0625a; # charger: Show all charger animations
  git cherry-pick 75bf203c6b35e965ff9ee7a0bc85b3b5fb08bf80; # healthd: allow custom charger
  git cherry-pick 0951fb068e73ae448a1eeea12a0f1d334137b876; # Partially revert "healthd: allow custom charger"

  croot;
  sed -i "s/\(ALOGV(\"message received msg=%d, ext1=%d, ext2=%d, obj=\)%x\(\",\)/\1%p\2/g" "frameworks/base/cmds/bootanimation/BootAnimation.cpp";
fi;

# System Output Cleaning
if [[ "$BuildMode" =~ "clean" ]]; then
  echo "";
  echo " [ Cleaning outputs ]";
  echo "";
  cd $AndroidDir/;
  make clean;
elif [[ ! "$BuildMode" =~ "nowipe" ]] && [[ ! "$BuildMode" =~ "test" || "$BuildMode" =~ "wipe" ]] && [ -d "$OutDir/system" ]; then
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
  if [[ "$BuildMode" =~ "kernel" ]]; then
    source $ScriptsDir/android_make_kernel.sh "release,otapackage" "aosp-mm6.0.1-";
  else
    source $ScriptsDir/android_brunch.sh "automatic,$BuildMode,otapackage";
  fi;

  # ROM Successful
  if [ ! -z "$AndroidResult" ] && [ -f "$AndroidResult" ]; then
    BuildSuccess="true";
  fi;

  # ROM Upload
  if [[ ! "$BuildMode" =~ "local" ]]; then
    cd $ScriptsDir/;
    if [[ ! "$BuildMode" =~ "test" ]]; then
      source $ScriptsDir/android_server_upload.sh "$AndroidResult" "Huashan/AOSP-CAF-6.0";
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
