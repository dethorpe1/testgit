#! /opt/perl/bin/perl -w

# feed-builder.pl 
# 
# Copyright, 2005 By John Bokma, http://johnbokma.com/ 
# 
# Last updated: 2005-12-07 00:31:41 -0600 

use strict; 
use warnings; 

use File::Find; 
use XML::RSS; 
use HTML::TreeBuilder; 

use Getopt::Long; 


# Set up default options. Can be overridden on command line
my $domain="www.britishplate.org.uk"; 
my $dir="/home/craign/nas1_craig/WebSites/bpas"; 
my $title="British Plate Armour Society page changes"; 
my $description="RSS feed of updated pages on the British Plate Armour Web site"; 
my $items = 12; 

GetOptions( 

    "dir=s"    => \$dir, 
    "domain=s" => \$domain, 
    "title=s"  => \$title, 
    "desc=s"   => \$description, 
    "items=i"  => \$items, 

) or show_help(); 

( 
    defined $dir 
    and defined $domain 
    and defined $title 
    and defined $description 

) or show_help(); 



# scan the given (web) directory for htm(l) files and 
# obtain the modification time of each found. 
my %file2time; 

find sub { 

    -f         or return; 
    /\.?html?$/ or return; 

    $file2time{ $File::Find::name } = ( stat )[ 9 ]; 

}, $dir; 

# sort the filenames on modification time, descending. 
my @filenames = sort { 

    $file2time{ $b } <=> $file2time{ $a } 

} keys %file2time; 

# keep the $items most recent ones 
@filenames = splice @filenames, 0, $items; 

# create the RSS file (version 1.0) 
my $rss = new XML::RSS( version => '1.0' ); 
$rss->channel( 

    title => $title, 
    link  => "http://$domain/", 
    description => $description, 
); 

# add an item for each filename 
for my $filename ( @filenames ) { 

    my ( $title, $description ) = 
        get_title_and_description( $filename ); 

    my $link = "http://$domain" . substr $filename, length $dir; 
    $link =~ s/index\.html?$//; 

    $rss->add_item( 

        title       => $title, 
        link        => $link, 
        description => $description, 

        dc => { 

            date => format_date_time( $file2time{ $filename } ) 
        } 
    ); 
} 

# output the result to STDOUT 
print $rss->as_string; 



sub show_help { 

    print <<HELP; 
Usage: feed-builder [options] > index.rss 
Options: 
    --dir       path to the document root 
    --domain    domain name 
    --title     title of feed 
    --desc      description of feed 
    --items     number of items in feed 
                (default is 12) 

Only --items is optional 
HELP

    exit 1; 
} 

# formats date and time for use in the RSS feed 
sub format_date_time { 

    my ( $time ) = @_; 

    my @time = gmtime $time; 

    return sprintf "%4d-%02d-%02dT%02d:%02dZ", 
        $time[5] + 1900, $time[4] + 1, $time[3], 
        $time[2], $time[1], $time[0]; 
} 

# extracts a title and a description from the given HTML file 
sub get_title_and_description { 

    my $filename = shift; 

    my $root = HTML::TreeBuilder->new; 
    $root->parse_file( $filename ); 

    # use the contents of the title element as title or 
    # a default if not present. 
    my $title_element = $root->look_down( _tag => 'title' ); 

    my $title = defined $title_element 
        ? $title_element->as_text 
        : 'No title'; 



    # use the contents of the first paragraph element as 
    # a description. Fall back to the title element, if 
    # present, otherwise use a default. 
    my $p_element = $root->look_down( _tag => 'p' ); 

    my $description = defined $p_element 
        ? $p_element->as_text 
        : ( defined $title_element 
            ? $title 
            : 'No description' 
        ); 

    # free memory 
    $root->delete; 

    return ( $title, $description ); 
} 

	
