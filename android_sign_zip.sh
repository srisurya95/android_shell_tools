#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);

echo "";
echo " [ Drag & Drop the zip file ]";
echo "";

printf " > ";
if [ ! -z "$1" ] && [ -f "$1" ]; then
  ZipFile="$1";
  echo "$ZipFile";
else
  read -e ZipFile;
fi;
ZipFile=${ZipFile//[\' ]/};
BackupFile="$ZipFile.original.zip";
NewSigFile="$ZipFile.signed.zip";

if [ -f "$BackupFile" ]; then
  rm -f "$BackupFile";
fi;
if [ -f "$NewSigFile" ]; then
  rm -f "$NewSigFile";
fi;

echo "";
echo " [ Signing the flashable zip ]";
echo "";

SignApkDir=$ScriptDir/android_signapk;
java -jar $SignApkDir/signapk-cm121.jar -w $SignApkDir/testkey.x509.pem $SignApkDir/testkey.pk8 $ZipFile $NewSigFile;

if [ -f "$NewSigFile" ]; then

  mv "$ZipFile" "$BackupFile";
  mv "$NewSigFile" "$ZipFile";
  rm "$BackupFile";

  echo "";
  echo "  $(basename $ZipFile) created.";
  echo "";

fi;

TimeDiff=$(($(date +%s)-$TimeStart));
echo "";
echo " [ Done in $TimeDiff secs ]";
echo "";
if [ -z "$2" ]; then
  read key;
fi;
