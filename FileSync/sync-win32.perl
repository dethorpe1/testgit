#! /opt/perl/bin/perl -w

use strict;
use Carp;
use Getopt::Std;
use File::Copy;
#use Win32;
use File::stat;

my $configFile = "F:\\My Documents\\perl\\sync\\testconfig.cfg";
my ($fromHost, $bFrom1, $line,$key);
my %opts;
my $forceCopy = 0;
my $silent = 0;

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
		if (! -d "$fromDir\\$file" && -f "$fromDir\\$file")
		{
			$fromStat = stat("$fromDir\\$file");
			if ( -e "$toDir\\$file") # if dest file exists then perform safty checks
			{
				$toStat = stat("$toDir\\$file");
				# Can't get rid of 1 sec diff on some files so allow a few seconds leyway
				# as not syncing in real time
				if ($fromStat->size == $toStat->size &&
					$fromStat->mtime > $toStat->mtime-2 &&
					$fromStat->mtime < $toStat->mtime+2 )
				{
					#print ("   File '$file' is identical, skipping\n");
					next;
				}
				if (($forceCopy == 0)&& ($fromStat->mtime < $toStat->mtime) )
				{
					if (Win32::MsgBox("File $file: Destination is newer than source.\nDo you want to overwrite ?",
									  MB_ICONQUESTION + 4,"Overwrite newer file?") == 7)		
					{
						print ("   Skipping file $file as dest is newer than source\n");
						next;
					}
				}
			}
			else {
				print ("$toDir\\$file dosn't exist\n"); 
			}
			
			if (defined $toStat) {
				print "   Copying '$file'. src [" . $fromStat->size ." bytes][". $fromStat->mtime ." secs], dest [" . $toStat->size . " bytes][" . $toStat->mtime . "secs]\n";
			}
			else {
				print "   Copying '$file'. src [" . $fromStat->size ." bytes][". $fromStat->mtime ." secs], new dest\n";
			}
			#chmod (0755 ,"$toDir\\$file") || carp "Failed to change mode of file $file, skipping file: $!";
			Win32::CopyFile ( "$fromDir\\$file","$toDir\\$file",1) || carp "Failed to copy file $file, skipping file: $!";
			# set the file time to the same as the remote file
			utime $fromStat->mtime, $fromStat->mtime, "$toDir\\$file";
		}
		elsif (-d "$fromDir\\$file" && $file !~ /^\./ )  # source file is a directory, but not a special one
		{
			# if its a directory than recurse down to it
			print ("  ## Matched directory $file, performing copy for it as well ....\n");
			copyFile ($filePattern, "$fromDir\\$file","$toDir\\$file");
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
chomp ($line = <CONFIG>); # 1st line contains column names
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
	exit if (Win32::MsgBox("$msg\nARE YOU SURE?",MB_ICONQUESTION | 4 ,"Are you sure?") == 7 );
}

#print "\nARE YOU SURE? (Y/N)";
#read (STDIN,$key,1);
#if (! (lc ($key) eq 'y')) {exit;}

# loop through the entries doing the copy
while (<CONFIG>)
{
	chomp $_;
	next if $_ =~ /^#|^$/ ; # skip comments and blank lines
	my ($File,$Dir1,$Dir2) = split (/,/,$_); # get the individual headings
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

#Win32::MsgBox("### COPY FINISHED ###",MB_ICONINFORMATION,"Copy Finished") unless ($silent);	
print "\n\n COPY FINISHED, PRESS ENTER TO EXIT.";
read (STDIN, $key, 1);
