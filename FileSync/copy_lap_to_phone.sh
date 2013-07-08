echo "Copy data files to phone  ..."
perl -w sync.perl -c sync-phone.cfg -f laptop $1
echo "DONE"
read key
