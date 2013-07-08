#! /opt/perl/bin/perl -w

use strict;
use warnings;

# perl script to convert html files produced by catallyst local test app to 
# static form for BPAS website. 
# Works as a filter taking input file on STDIN and outputs on STDOUT

# takes argument of number of subdirs down static page is going to be, defaults to 0 
my $subDirCount = 0;
my $relativePath="";
$subDirCount = shift @ARGV if defined $ARGV[0];

# Work out relative path based on number of sub dirs
for (my $i=0; $i < $subDirCount; $i++) {
	$relativePath .= "../";
} 

while (<>) {
	# Strip catalyst bit of redirect links
	$_ =~ s/http:\/\/localhost\/redirect\//$relativePath/;
	
	# Strip of catalyst bit of static links
	$_ =~ s/http:\/\/localhost\/static\//$relativePath/;
	
	# Convert catalyst URLS to static links
	$_ =~ s/http:\/\/localhost\/(shows)\/([^"]*)/${relativePath}${1}\/${2}.html/;
	
	print $_;
}