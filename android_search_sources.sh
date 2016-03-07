#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;

cd $AndroidDir/;
if [ ! -z "$1" ]; then
  pattern="$1";
  if [ ! -z "$2" ]; then
    path="$2";
  else
    path="";
  fi;
  pathEdit="false";
else
  pattern="";
  path="";
  pathEdit="";
fi;

clear;
echo -e \\033c;
echo "";
echo " [ Pattern to search for ]";
echo "";
printf "  Source code to search for : ";
if [ -z "$pattern" ]; then
  read -e pattern;
else
  echo "$pattern";
fi;

if [ ! -z "$pattern" ]; then

  echo "";
  echo "  Path to look into...";
  printf "   Enter for all, example 'device/sony/$PhoneName/' : ";
  if [ -z "$1" ]; then
    read -e $path;
  else
    echo "$path";
  fi;

  echo "";
  echo "";
  echo " [ Searching for '$pattern' in ./$path ]";
  echo "";
  TimeStart=$(date +%s);
  GREP_COLORS='fn=1;1' grep --include=\*.{java,c,cpp,h,sh,mk,xml,te} -nr ./$path -e "$pattern" | tee $SearchFile;
  # n : show found line numbers / w : entire words / l : files matching / r : recursive
  TimeDiff=$(($(date +%s)-$TimeStart));

  echo "";
  echo "";
  echo " [ Done in $TimeDiff secs ]";
  echo "";

fi;

if [ -z "$1" ]; then
  read key;
fi;
