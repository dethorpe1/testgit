#! /usr/bin/ksh
if [[ $# != 1 ]]
then
	print "Usage $0 <sleep time>"
	exit 1
fi

i=1
while true
do
	print "Writing file $i ..."
	echo "File $i" > ~/PORTAL_id1234_2005$i.log
	echo "File $i" > ~/WSI_id1234_2005$i.log
	echo "File $i" > ~/eSAP_id1234_2005$i.log
	let i=i+1
	print "Sleeping for $1 seconds ..."
	sleep $1
done
