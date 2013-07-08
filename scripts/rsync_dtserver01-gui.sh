#! /bin/bash

# Sync documents area
# NEED to sudo this script



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
	export OPTS="--delete"
fi

export PWORD_FILE="/home/craign/.rsync"

if [[ ! -z $general ]]
then 
	echo "Syncing general files .."
	echo "   Documents ..."
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Documents craign@dtserver01::craign_datastore
	echo "   WebSites ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/WebSites craign@dtserver01::craign_datastore
	echo "   eclipse ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/eclipse craign@dtserver01::craign_datastore
	echo "   BPAS ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/BPAS craign@dtserver01::craign_datastore
	echo "   DethorpeLimited ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/DethorpeLimited craign@dtserver01::craign_datastore
	echo "   .mozilla-thunderbird ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/.mozilla-thunderbird craign@dtserver01::craign_datastore
	# don't delete extraneous on crypt keeper files as if its not mounted will delete everything!
	echo "   keeper ..."	
	rsync -a --password-file $PWORD_FILE /home/craign/keeper craign@dtserver01::craign_datastore
fi

if [[ ! -z $media ]]
then
	echo "Syncing media files .."	
	echo "   Music ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Music craign@dtserver01::craign_datastore
	echo "   Pictures ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Pictures craign@dtserver01::craign_datastore
	echo "   Videos ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Videos craign@dtserver01::craign_datastore
	echo "   eBooks ..."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/eBooks craign@dtserver01::craign_datastore
fi

echo "FINISHED, hit RETURN to exit >"
read $key

