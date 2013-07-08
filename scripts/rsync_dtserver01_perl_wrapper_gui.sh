#! /bin/bash

# Sync documents area
# NEED to sudo this script

SCRIPT_PATH="/home/craign/eclipse/workspace/scripts"

opts=`zenity --list --checklist --column "Select" --column "Action" TRUE "Sync General" FALSE "Sync Media" FALSE "Delete Extraneous"`
echo $opts

# Read the delimited options selected and set variables
SaveIFS=$IFS;IFS='|'
for opt in $opts
do
  case $opt in
    "Sync General") general=1
		    ;;
    "Sync Media") media=1
		    ;;
    "Delete Extraneous") delete=1
		;;
  esac
done
IFS=$SaveIFS

if [[ ! -z $delete ]]
then
	echo "Deleteing extraneous files from dest"
	export sync_options="-d"
fi

export PWORD_FILE="/home/craign/.rsync"

if [[ ! -z $general ]]
then
	$SCRIPT_PATH/rsyncwrapper.perl -t general $sync_options 
fi

if [[ ! -z $media ]]
then
	$SCRIPT_PATH/rsyncwrapper.perl -t media $sync_options 
fi


echo "
FINISHED, hit RETURN to exit >"
read $key

