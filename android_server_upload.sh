#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;

# BasketBuild Upload Credentials
export UploadServer="s.basketbuild.com/webupload";
export UploadUserName="Username.s";
export UploadPassword="";
export UploadFolder="Path/To/Folder";

# Create  ~/.bash_android.basketbuild.**name**.rc with the exports to override the credentials
if [ ! -z "$3" ] && [ -f ~/.bash_android.basketbuild.$3.rc ]; then
  source ~/.bash_android.basketbuild.$3.rc;
elif [ -f ~/.bash_android.basketbuild.main.rc ]; then
  source ~/.bash_android.basketbuild.main.rc;
fi;

SendFile="$1";
if [ ! -z "$2" ]; then
  UploadFolder="$2";
else
  UploadFolder="Development";
fi;

echo "";
echo -e " \e[1;33m[ Uploading to the server - User '$UploadUserName' - Path '$UploadFolder' ]\e[0m";
echo "";
if [ ! -z "$SendFile" ] && [ -f "$SendFile" ] && [ ! -z "$UploadPassword" ]; then

  SendFileName=$(basename "$SendFile");
  SendFileExt=${SendFileName##*.};
  SendFileSize=$(stat -c "%s" "$SendFile");
  SendFileType='';

  if [[ "$SendFileExt" =~ 'zip' ]]; then
    SendFileType='application/zip';
  fi;

  echo "   File '$(basename $SendFile)' uploading...";
  echo "";

  curl -L -# --dump-header .headers \
          -F "ftp_user=$UploadUserName" \
          -F "ftp_pass=$UploadPassword" \
          -F "openFolder=~$UploadFolder" \
          -F "ip_check=1" \
          -F "login=1" \
          -F "login_save=1" \
          -F "submit=Login" \
          "https://$UploadServer/" > /dev/null;

  curl -X POST -L -# --progress-bar -b .headers \
          -H "Cache-Control: no-cache" \
          -H "X-Filename: $SendFileName" \
          -H "X-Requested-With: XMLHttpRequest" \
          -H "X-File-Size: $SendFileSize" \
          -H "X-File-Type: $SendFileType" \
          -H "Content-Type: multipart/form-data" \
          --data-binary @"$SendFile" \
          -o .uploadoutputs \
          "https://$UploadServer/?ftpAction=upload&filePath=";

  echo "";
  echo -e "  \e[1;32mUploaded to :\e[0m https://basketbuild.com/filedl/devs?dev=${UploadUserName:0:-2}&dl=${UploadUserName:0:-2}/$UploadFolder/$SendFileName ";

  if [ -f "./.headers" ]; then
    rm "./.headers";
  fi;

  if [ -f "./.uploadoutputs" ]; then
    rm "./.uploadoutputs";
  fi;

elif [ -z "$UploadPassword" ]; then
  echo "  FTP Credentials not found...";
else
  echo "  File '$SendFile' not found...";
fi;

TimeDiff=$(($(date +%s)-$TimeStart));
echo "";
echo -e " \e[1;37m[ Done in $TimeDiff secs ]\e[0m";
echo "";
