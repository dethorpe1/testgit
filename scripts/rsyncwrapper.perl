#! /opt/perl/bin/perl -w

use strict;
use Getopt::Std;
use constant TRUE => 1;
use constant FALSE => 0;
use constant TRUE_STR => "true";
use constant FALSE_STR => "false";
use XML::Simple;
use Data::Dumper;
use File::Basename;

my (%opts, $config);
my $deleteOpt = "";
my $PWORD_FILE = "~/.rsync";
my $syncType = ""; 
my %syncOptions;
my @syncList = (); 
my $debug = 0;

#############################################################################

=head1 usage()

Display uasge and exit

IN: Optional Error message to print

=cut

#############################################################################

sub usage {
	print "ERROR: " . $_[0] . "\n" if defined $_[0];
	print <<END;
	Script to sync files using rsync
	Reads rsync details and directories for each type to sync from ./rsyncwrapper.xml
	
	USAGE: print "$0 [-t <type> -e -d]
			-t <types> = list of types to sync, : seperated. Must match what is in XML config file.
			-e = Delete Extraneous.
			-d = Debug mode (verbose logging)
			
	If -t not specified GUI is used to select options.
END
	exit 1;	
}

#############################################################################

=head1 do_gui()

Display GUI using Zenity to allow user to select  options

IN: Default DeleteExtraneous flag.
	"TRUE" | "FALSE"
OUT: hash with options
	types => array of types to sync
	del   => Delete Extraneous flag ("TRUE"|"FALSE")

=cut

#############################################################################

sub do_gui($) {
	my $del = uc($_[0]);
	my %retHash;
	# call zenity to do GUI
	my $gui_options=`zenity --list --checklist --column "Select" --column "Action" TRUE "Home to NAS1" FALSE "Media to NAS1" $del "Delete Extraneous"`;
	print "do_gui(): Zenity returned: " . $gui_options . "\n" if $debug;
	chomp $gui_options;
	# parse zenity return into hash
	if (defined $gui_options and length ($gui_options) > 0) {
		my @typesArray=();
		$retHash{del} = FALSE_STR;
		foreach my $option (split (/\|/,$gui_options)) {
			print "do_gui(): Processing option $option\n";
			if ($option eq "Home to NAS1") {
				push (@typesArray,"home-to-NAS1");
			} elsif ($option eq "Media to NAS1"){
				push (@typesArray,"media-to-NAS1");
			} elsif ($option eq "Delete Extraneous"){
				$retHash{del} = TRUE_STR;
			} else {
				print "WARNING: unknown option $option, ignoring";
			}

			# ignore any other options
		}
		$retHash{types} = \@typesArray if @typesArray;
		print "do_gui(): returning option hash: \n" . Dumper(%retHash) . "\n" if $debug;
	}
	return %retHash;

}

#################
# START OF MAIN #
#################

# Check for Command line options first
getopt ('t:ed',\%opts);
if (exists $opts{"e"}) {
	$syncOptions{del} = TRUE_STR ;	
}
else {
	$syncOptions{del} = FALSE_STR ;	
	
}
$debug = 1 if exists $opts{"d"};

# if type not specifed use GUI options
if (!defined $opts{"t"}) {
	%syncOptions = do_gui($syncOptions{del});
	usage ("No sync types selected in GUI") if (!exists $syncOptions{types});
}
else {
	$syncOptions{types} = \(split (/:/,$opts{"t"}));
}

# get the rsync config
my $scriptPath = dirname ($0);
my $configFile = "$scriptPath/rsyncwrapper.xml";

print ("Reading config file: $configFile\n");
eval {$config = XMLin($configFile, ForceArray =>["entry"],GroupTags =>{sync => 'entry'},
								   #KeyAttr => {sync => "type"},
								   SuppressEmpty => 1 )
};
if ($@) {
	$@ =~ s/^[\n\r]+//; # returned error has leading new line
	usage ("ERROR: Error Reading Config file $configFile: $@");
}

print ("DEBUG: Full config hash: " . Dumper ($config)) if $debug;

# Process each entry in the synclist built from config
foreach my $type (@{$syncOptions{types}}) {
	print ("\n> Syncing type '$type' ... ");
	my $typeArray = $config->{sync}{$type}{entry};
	foreach my $entry (@$typeArray) {
		print("\nDEBUG: Config Entry for type $type:\n" . Dumper($entry)) if $debug;
		print ("\n Syncing source: " . $entry->{source} . "... ");
		# override delete opt if not allowed for this node
		$deleteOpt="";
		if ($entry->{allowdelete} eq "true" and lc($syncOptions{del})  eq "true" ) {
			$deleteOpt=" --delete";
			print (" (Deleteing extraneous entries)");
		}
		system ("rsync -a $deleteOpt --no-perms --password-file $PWORD_FILE $entry->{source} $entry->{target}");
		
	}
}

print "##### SYNC FINISHED. PRESS ENTER TO EXIT >";
my $key;
read STDIN, $key, 1;

