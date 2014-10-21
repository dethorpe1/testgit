#! /bin/bash 

# Script to generate the BPAS website pages from the MySQL DB's

export BPASSCRIPT_DIR=$HOME/git/testgit/BPASscripts
export CAT_BPAS_SCRIPT_DIR=$HOME/git/cat_bpas/cat_bpas/script
export WEBSITE_DIR=$HOME/nas1_craig/WebSites/bpas
export SECURE_DIR=$HOME/Dropbox/BPAS/DBReports

# run catalyst test apps to generate static pages
# Note: Use perl filter to strip catalyst root from links
# ===================================
cd $CAT_BPAS_SCRIPT_DIR

echo "# Generating show summary list to website ..."
./cat_bpas_test.pl /shows/summarylist | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/shows/summarylist.html

echo "# Generating show full list to website ..."
./cat_bpas_test.pl /shows/fulllist | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/shows/fulllist.html

echo "# Generating show attend list to website ..."
./cat_bpas_test.pl /shows/attendlist | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/members/attendlist.html

#  Non-website reports to secure storage
#  =====================================
echo "# Generating renewals report to DB & secure storage ..."
./cat_bpas_test.pl /query/renewalsdue/1 | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/admin/renewalsdue.html
htmldoc --webpage --portrait -f $SECURE_DIR/renewalsdue.pdf $WEBSITE_DIR/admin/renewalsdue.html

echo "# Generating offline members report to DB & secure storage ..."
./cat_bpas_test.pl /query/offlinemembers | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/admin/offlinemembers.html
htmldoc --webpage --portrait -f $SECURE_DIR/offlinemembers.pdf $WEBSITE_DIR/admin/offlinemembers.html

echo "# Generating contact list to DB & secure storage ..."
./cat_bpas_test.pl /members/contactlist | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/admin/contactlist.html
htmldoc --webpage --footer ... --toclevels 2 --landscape --left 0.5in --fontsize 10 --fontspacing 0.2 -t pdf14 --no-embedfonts --jpeg=75 -f $SECURE_DIR/contactlist.pdf $WEBSITE_DIR/admin/contactlist.html

echo "# Generating email list to DB & secure storage ..."
./cat_bpas_test.pl /query/emaillist | perl -w "$BPASSCRIPT_DIR/convert_cat_to_static.pl" 1 > $WEBSITE_DIR/admin/emaillist.html
htmldoc --webpage --portrait --links -f $SECURE_DIR/emaillist.pdf $WEBSITE_DIR/admin/emaillist.html

# Run standalone scripts
# ======================
cd $BPASSCRIPT_DIR

# guestbook - mySQL
# =================
# import any new mails - TBD
# TBD- java -DHOME="$HOME" -cp $HOME/eclipse/workspace/Guestbook/build/Guestbook.jar com.dethorpe.guestbook.Guestbook

# generate web page
#echo "# Generating guestbook to website ..."
#./guestbookweb.perl

# Market - mySQL
# ==============
#echo "# Generating market to website ..."
#./marketweb.perl

# RSS feed
# ========
echo "# Generating RSS feed to website ..."
./feed-builder.pl > $WEBSITE_DIR/BPAS_RSS.xml

echo "Press ENTER to exit:"
read
