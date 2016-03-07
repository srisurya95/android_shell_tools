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
  git cherry-pick ee0b6151e2989600131ed4ccc1eaf2682826b2a1; # [NEEDED] build: Disable relocation packing on recovery and utility executables
  git cherry-pick dcf7d09d7bab319e860b8bcb9d506cf9834948de; # envsetup: add mk_timer
  git cherry-pick a331253dd2f538c642899bc4b49c54185c9ef770; # mms: introduce a shortcut to quickly rebuild kernel/boot.img

  croot;
  cd ./bionic;
  # [NEEDED] bionic: linker: Load shim libs *before* the self-linked libs
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_bionic refs/changes/02/132902/1 && git cherry-pick FETCH_HEAD;
  # [NEEDED] Add prlimit to LP32.
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_bionic refs/changes/96/135596/1 && git cherry-pick FETCH_HEAD;

  croot;
  cd ./art/;
  # [RECOMMENDED] ART Updates
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/91/118591/1 && git cherry-pick FETCH_HEAD;
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/15/135715/3 && git cherry-pick FETCH_HEAD;
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/27/136027/1 && git cherry-pick FETCH_HEAD;
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/28/136028/1 && git cherry-pick FETCH_HEAD;
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/29/136029/1 && git cherry-pick FETCH_HEAD;
  git fetch http://AdrianDC@review.cyanogenmod.org/a/CyanogenMod/android_art refs/changes/30/136030/1 && git cherry-pick FETCH_HEAD;
  # [NEEDED] ART fix
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_art;
  git cherry-pick c48159c497c567f7f14360baa7e513e67e31a30c; # ART: Disable Clang for arm

  croot;
  cd ./system/core/;
  # [NEEDED] Healthd and charger commits
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_system_core;
  git cherry-pick a57098bb9ee2a3d1beb93bb52fa0873f53e0625a; # charger: Show all charger animations
  git cherry-pick 75bf203c6b35e965ff9ee7a0bc85b3b5fb08bf80; # healthd: allow custom charger
  git cherry-pick 0951fb068e73ae448a1eeea12a0f1d334137b876; # Partially revert "healthd: allow custom charger"

  croot;
  cd ./frameworks/opt/telephony/;
  # [NEEDED] Update RIL support
  git fetch https://github.com/AdrianDC/aosp_huashan_build.git android_frameworks_opt_telephony;
  git cherry-pick a5fa7a9447a4f327a674957db9ea2f2ccda33c83; # Revert "Use radio availability to sync card status instead of radio on"
  git cherry-pick 822a8d90f93aa42d9e1947e68c1662d21cf9eefd; # UiccController: use registerForAvailable only for persist.radio.apm_sim_not_pwdn
  git cherry-pick 565be597909135738fc5f896daf610bae2f9889d; # Telephony: Allow more RIL methods to be overridden
  git cherry-pick bb319c30d734de272e6259edf483e39265bf7cb5; # RIL: forward port support for mQANElements
  git cherry-pick 3277511ff4833e1262a15647c5bc23c039eff9f8; # RIL: Make mQANElements configurable by property

  # croot;
  # cd ./frameworks/av/;
  # git revert --no-edit 37f1ee41c2aae2a2b978092d85408e0c28ca71be; # stagefright: Fix voodoo ifdefs

  # croot;
  # sed -i "s/\(ALOGV(\"message received msg=%d, ext1=%d, ext2=%d, obj=\)%x\(\",\)/\1%p\2/g" "frameworks/base/cmds/bootanimation/BootAnimation.cpp";
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
