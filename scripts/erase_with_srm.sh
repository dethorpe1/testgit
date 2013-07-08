#! /bin/bash
#echo $@
#/usr/bin/srm -v "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
# Erases selected files using srm
# Uses zenity for conformation and progress dialogs

filelist=`echo $@ | sed 's/\n/,/g'`
zenity --question --title "Confirm" --text "Secure Erase:\n $filelist\n\nAre you sure?" --width 500
if [[ $? == 0 ]]
then
	/usr/bin/srm -v "$@" | zenity --progress --pulsate --auto-close --text "Erasing $filelist ..." --width 500
fi                  

