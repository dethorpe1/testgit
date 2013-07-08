#! /opt/perl/bin/perl -w

use strict;
use Carp;
use Getopt::Std;
use File::Copy;
use File::stat;

my $configFile = "";
my ($fromHost, $bFrom1, $line,$key);
my %opts;
my $forceCopy = 0;
my $silent = 0;

#$|=1;
sub copyFile 
{
	my ($filePattern, $fromDir, $toDir) = @_;

	# filenames can be reg expressions so need to read the 'from' directory
	# and then only copy those files that match 
	
	# Check dest dir exists and create it if it dosn't
	if ( ! -e $toDir && !mkdir ($toDir))
	{
		carp "Failed to Create destination directory $toDir, skipping pattern: $!";
		last;
	}

	opendir (DIR, $fromDir) || carp "Unable to open source directory $fromDir, skipping: $!";
	my @files = grep (/$filePattern/, readdir(DIR)); # get list of files that match.
	my $fromStat;
	my $toStat;
	
	foreach my $file (@files)
	{
		# check is source file is not directory	
		if (! -d "$fromDir/$file" && -f "$fromDir/$file")
		{
			$fromStat = stat("$fromDir/$file");
			if ( -e "$toDir/$file") # if dest file exists then perform safty checks
			{
				$toStat = stat("$toDir/$file");
				# Can't get rid of 1 sec diff on some files so allow a few seconds leyway
				# as not syncing in real time
				if ($fromStat->size == $toStat->size &&
					$fromStat->mtime > $toStat->mtime-2 &&
					$fromStat->mtime < $toStat->mtime+2 )
				{
					#print ("   File '$file' is identical, skipping");
					next;
				}
				if (($forceCopy == 0)&& ($fromStat->mtime < $toStat->mtime) )
				{
					print "\nFile $file: Destination is newer than source.\nDo you want to overwrite (Y/N)?";
					my $key;
					
					$key=<STDIN>;
					chomp($key);
					if (uc($key) ne "Y")		
					{
						print ("\n   Skipping file $file as dest is newer than source\n");
						next;
					}
				}
			}
			else {
				print ("$toDir/$file dosn't exist\n"); 
			}
			
			if (defined $toStat) {
				print "   Copying '$file'. src [" . $fromStat->size ." bytes][". $fromStat->mtime ." secs], dest [" . $toStat->size . " bytes][" . $toStat->mtime . "secs]";
			}
			else {
				print "   Copying '$file'. src [" . $fromStat->size ." bytes][". $fromStat->mtime ." secs], new dest\n";
			}
			#chmod (0755 ,"$toDir/$file") || carp "Failed to change mode of file $file, skipping file: $!";
			copy ( "$fromDir/$file","$toDir/$file") || carp "Failed to copy file $file, skipping file: $!";
			# set the file time to the same as the remote file
			utime $fromStat->mtime, $fromStat->mtime, "$toDir/$file";
		}
		elsif (-d "$fromDir/$file" && $file !~ /^\.{1,2}$/ )  # source file is a directory, but not a special one
		{
			# if its a directory than recurse down to it
			print ("  ## Matched directory $file, performing copy for it as well ....\n");
			copyFile ($filePattern, "$fromDir/$file","$toDir/$file");
			print ("  ## Finished copying sub directory $file\n");
		}
	}
	closedir(DIR);
}

####
# MAIN PROCESSING
####

# read options
getopts ('f:c:Fs',\%opts);

unless ($opts{"f"}) { croak "-f option is mandatory and requires an argument";}

if (defined($opts{"f"}) && $opts{"f"} ne "1") { $fromHost = $opts{"f"}; }
if (defined($opts{"c"}) && $opts{"c"} ne "1") { $configFile = $opts{"c"}; }
if (defined($opts{"F"})) { $forceCopy = 1; }
if (defined($opts{"s"})) { $silent = 1; }

# open the config file
open (CONFIG, "<$configFile") || croak "Unable to open config file $configFile";
$line = <CONFIG>;
chomp ($line); # 1st line contains column names
chomp ($line); # 1st line contains column names

my ($fileHead,$host1,$host2) = split (/,/,$line); # get the individual headings

# work out the required sync direction from the column names and options
my $msg;
unless ($silent) {
	if ($host1 eq $fromHost )
	{
		$bFrom1 = 1;
		$msg =  "Copying from $host1 to $host2";
	} 
	elsif ($host2 eq $fromHost ) 
	{
		$bFrom1 = 0;
		$msg = "Copying from $host2 to $host1";
	} 
	else
	{
		croak ("Host in -f option [$fromHost] dosn't match entry in config file [$line]");
	}
	print ("$msg\n");
	print ("## ARE YOU SURE (Y/N)?");
	$key=<STDIN>;
	chomp($key);
	exit if (uc($key) ne "Y");
}

# loop through the entries doing the copy
while (my $line = <CONFIG>)
{
	chomp $line;
	next if $line =~ /^#|^$/ ; # skip comments and blank lines
	print ("Processing line: $line\n");
	my ($File,$Dir1,$Dir2) = split (/,/,$line); # get the individual headings
	if ($bFrom1) 
	{
		print ("\n## STARTING COPY OF PATTERN '$File', FROM '$Dir1' TO '$Dir2'....\n");
		copyFile ($File, $Dir1,$Dir2);
	}
	else
	{
		print ("\n## STARTING COPY OF PATTERN '$File', FROM '$Dir2' TO '$Dir1'....\n");
		copyFile ($File, $Dir2,$Dir1);
	}
}

print "\n\n COPY FINISHED, PRESS ENTER TO EXIT.\n";
$key=<STDIN>;
