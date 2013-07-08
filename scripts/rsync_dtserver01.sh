#! /bin/bash

# Sync general documents area
# NEED to sudo this script
if [[ "$2" == "delete" ]]
then
	echo "Deleteing extraneous files from dest"
	export OPTS="--delete"
fi

export PWORD_FILE="/home/craign/.rsync"

if [[ "$1" == "general" || "$1" == "all" ]]
then 
	echo "Syncing general files .."
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Documents craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/WebSites craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/eclipse craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/BPAS craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/DethorpeLimited craign@dtserver01::craign_datastore
fi

if [[ "$1" == "media" || "$1" == "all" ]]
then
	echo "Syncing media files .."	
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Music craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Pictures craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/Videos craign@dtserver01::craign_datastore
	rsync -a $OPTS --password-file $PWORD_FILE /home/craign/eBooks craign@dtserver01::craign_datastore
fi

