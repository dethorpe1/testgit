#! /usr/bin/perl -w
# #! perl -w - use this on windows
################################################################################
#
# SCRIPT: FetchLogs.pl
#
# AUTHOR: Craig Nicholas. 
#
# DESCRIPTION:
#  Script to transfer files between servers. Can run
#  in push or pull mode. i.e. send files from a local server to a remote 
#  server, or pull files from a remote server to a local server.
#
# USAGE:
#       FetchLogs [ -s <sleep time> -c <config file> -h -d [<level>]]
#          sleep time = Number of seconds to sleep between fetches, 0 = do once only. 
#						OPTIONAL, default = ${sleepTime}secs
#          config file = Name of config file containing details of systems to fetch from.
#                        OPTIONAL, default = ${configFile}
#		   -h = Show help
#          -m mode = mode/direction of transfer PUT|GET. OPTIONAL default = PUT
#          -d [<level>] = turn on debug. if level = 1, turn on full FTP debug as well
#
# CONFIG FILE:
#
# Each line is comma seperated with the format:
# 	system,host,user,remotedir,localdir,pattern,password,rename,pattern
#
# The fields are:
#   system    = Name of system entry is for.
#   host      = Hostname or IP address of server to connect to.
#   user      = User name to logon with.
#   remotedir = Directory on remote system containing logs. Can be
#               absolute or relative from ftp users home directory. 
#               If no Change of directory is required then set 
#               to . (e.g. if users home directory is the log directory).
#   localdir  = Directory on local system containing logs in. Can be 
#               absolute or relative from scripts home directory. 
#   pattern   = Reguler expression defining file names to transfer. Can
#               use full perl reguler expression syntax.
#   password  = Password of user to logon with.
#   rename    = flag indicating whether to rename file on transfer. 
#			    If Y and in GET mode will have host from config file entry 
#				prefixed to the name on the destination system
#				If Y and in PUT mode will have current system hostname prefixed 
#				to the name on the destination system
#				If S in either mode will have <system> from config file line
#				prefixed to the name on the destination system
#   pattern   = Pattern defining a complex rename of the source file. Actioned
#				after the host name rename above so that can be included in the 
#				pattern. Defines the name to use for transfered files with parameters
#				representing parts of the source name, where the source name is
#				split on punctuation chars
#	dailymode = Transfered file operate in daily mode. The fetched or pushed file must be 
#               written to a sub-folder based on the date of the fiels in YYYYMMDD format. 
#			    to use this feature each file must will have a date stamp in it that can be 
#				captured by the reguler expression and will appear in the $1 variable 
#
# Example of pattern based rename:
#  file name			 = app.log.2006-01-19.txt
#  after hostname rename = host-a01-uat001_app.log.2006-01-19.txt
#  field numbers 		 = $1   $2  $3     $4  $5  $6   $7 $8 $9
#  Dest pattern 		 = OUT_$3_$6$7$9000000.log
#  new name 		     = OUT_uat001_20060119000000.log
#
################################################################################

use lib "perl";
use strict;
use Getopt::Std;
use Carp;
use Net::FTP;
use Sys::Hostname;
use constant MODE_PUT => 1;
use constant MODE_GET => 2;
use constant TRUE => 1;
use constant FALSE => 0;
use constant STAT_MOD_TIME_POS => 9;

$Carp::Verbose=1;

# GLOBALS
my ($debug) = FALSE;
my ($ftpDebug) = FALSE;
my (%opts, %cfgHash, $lastLogDate);
# config parameters and defaults
my ($sleepTime, $logFile, $configFile, $mode) = (3600, "FetchLogs.log", "FetchLogs.cfg", MODE_PUT) ;

####################
# local loggers.   #
####################
sub myCroak($)
{
	my ($text) = $_[0];
	logError ($text);
	croak($text);
}

sub logError($)
{
	logger ("ERROR," . $_[0]);	
}

sub logInfo($)
{
	logger ("INFO," . $_[0]);	
}

sub logWarning($)
{
	logger ("WARNING," . $_[0]);	
}

sub logger($) 
{
	my ($text) = $_[0];
	my ($sec, $min, $hour, $day, $month, $year ) = ( localtime ) [ 0, 1, 2, 3, 4, 5 ];
	my ($currLogDate) = sprintf("%d-%02d-%02d", $year+1900,$month+1,$day);
	my ($timeStamp)   = sprintf("%s %02d:%02d:%02d",$currLogDate,$hour,$min,$sec); 
	
	# See if we have rolled over a day
	if ($lastLogDate ne $currLogDate)
	{
		# rotate the log file
		rename ($logFile, "$logFile.$lastLogDate") || logWarning("Unable to rotate log file. $!");
		$lastLogDate = $currLogDate;
	}

	open  (LOG_FILE, ">>$logFile") || croak ("$timeStamp,ERROR,Unable to open logfile $logFile. $!");
    print (LOG_FILE "$timeStamp,$text\n"); 
    close (LOG_FILE);

	print "$timeStamp,$text\n" if $debug;
}

#################################
## Print the usage information  #
#################################
sub usage()
{
    print <<EOD;
    DESCRIPTION
      Script to transfer files between servers. Can run
      in push or pull mode. i.e. send files from a local server to a remote 
      server, or pull files from a remote server to a local server.
    USAGE
       FetchLogs [ -s <sleep time> -c <config file> -h -d [<level>] -m <mode>]
          sleep time = Number of seconds to sleep between fetches, 0 = do once only. 
                       OPTIONAL, default = ${sleepTime}secs
          config file = Name of config file containing details of systems to fetch from.
                        OPTIONAL, default = ${configFile}
          -h show help
          -m mode = mode/direction of transfer. [PUT|GET]. OPTIONAL default = PUT
          -d [<level>] = turn on debug. if level = 1, turn on full FTP debug as well (must be last option)

EOD
}

###############################################################
## Function to get all the required info from the config file #
## param1 = Path Name of config file                          #
###############################################################
sub getConfig($)
{
    local $_; # protect the callers $_ variable
    my ($file) = @_;
    
    
    open (CFG_FILE, $file) || myCroak ("Unable to open config file $file. $!");
	
	# If on UNIX Check the files permissions. For security must only be readable by 
    # the current user. Can't do this on windows
    if (!defined $ENV{windir}) {
	    my $mode = ((stat(CFG_FILE))[2]) & 07777;
		myCroak (sprintf("Config file has incorrect permissions (%04o). Must only be readable by owner",$mode))
		    if ($mode ne 0600 );
    }

    while (<CFG_FILE>)
    {
        chomp;
        next if ($_ =~ "^#" || $_ eq "" ); # skip comments and blank lines
        my @line = split (/,/);
    	myCroak("Invalid config File line. '$_'") 
    		if ( $#line < 6 || !defined ($line[0]) || $line[0] eq "");
    		
    	# load the hash
    	$cfgHash{$line[0]} = { 	SYSTEM =>    $line[0],
    							HOST => 	 $line[1],
    							USER => 	 $line[2],
    							REMOTEDIR => $line[3],
    							LOCALDIR =>  $line[4],
    							PATTERN =>   $line[5],
    							PASSWORD =>  $line[6],
    							RENAME =>    $line[7],
    							RENAME_PATTERN =>   $line[8],
    							DAILY_MODE =>$line[9] };
    	
    }
    close (CFG_FILE);
}

##########################################################
## Function to perform file rename operations. 
## Does the Hostname prefix rename and/or the pattern rename
##
## param1 = Config hash Reference for system
## param2 = Original filename
## returns new file name
##
# Example of pattern based rename:
#  file name			 = app.log.2006-01-19.txt
#  after hostname rename = host-a01-uat001_app.log.2006-01-19.txt
#  field numbers 		 = $1   $2  $3     $4  $5  $6   $7 $8 $9
#  Dest pattern 		 = OUT_$3_$6$7$9000000.log
#  new name 		     = OUT_uat001_20060119000000.log
##########################################################
sub renameFile($$)
{
	my ($cfgHashRef, $fileName) = @_;

	# Add hostname prefix to file name if specified in config file
	# otherwise use identical name.
	if ( $cfgHashRef->{RENAME} eq "Y")
	{
		if ($mode == MODE_GET) {
			$fileName = "$cfgHashRef->{HOST}_$fileName";
		}
		else {
			$fileName = hostname . "_$fileName";
		}			
	}
	elsif ( $cfgHashRef->{RENAME} eq "S") {
		$fileName = "$cfgHashRef->{SYSTEM}_$fileName";
	}

	# Do pattern based rename if specified.
	# Done after hostname addition so that can be included in the pattern rename 
	if ( defined ($cfgHashRef->{RENAME_PATTERN}) &&  
		 length($cfgHashRef->{RENAME_PATTERN}) > 0)
	{
		my $newFileName=$cfgHashRef->{RENAME_PATTERN};
		my @nameFields = split (/[[:punct:]]/, $fileName);
		for (my $loop=1; $loop <= $#nameFields+1; $loop++)
		{
			$newFileName =~ s/\$${loop}/$nameFields[$loop-1]/g;
		}

		$fileName=$newFileName;
	}
	
	return $fileName;
}

#####################################################################
## Function to perform file fetch                                   #
## param1 = system name from config file                            #
## param2 = Hash reference containing other fields from config file #
#####################################################################
sub fetchFiles($$)
{
	my ($sys,$cfgHashRef) = @_;
	my $ftp ;
	my $localFileName;

	# create the connection	
	$ftp =  Net::FTP->new($cfgHashRef->{HOST}, Debug => $ftpDebug);

	unless (defined $ftp)
	{
		logError("Unable to connect to system $sys. $@");
		return;
	}
	
	# login
	unless($ftp->login($cfgHashRef->{USER}, $cfgHashRef->{PASSWORD})) 
	{
		logError("Unable to login to remote system $sys." .  $ftp->message());
		return;
	}
	
	# go to required remote directory
	unless($ftp->cwd("$cfgHashRef->{REMOTEDIR}"))
	{
		logError("Unable to change to remote dir for system $sys." .  $ftp->message());	
		return;
	}	
	
	# Check the local directory exists
	unless (-e $cfgHashRef->{LOCALDIR} && -d $cfgHashRef->{LOCALDIR})
	{
		logError("Local directory '$cfgHashRef->{LOCALDIR}' dosn't exist for system $sys.");
		return;
	}

	# List remote files
	my @remoteFiles = $ftp->ls();
	
	# loop through the remote files
	for my $file (@remoteFiles)
	{
		my $fileDate;
		next unless ($file =~ /$cfgHashRef->{PATTERN}/); # skip files that don't match 
		$fileDate = $1 if (defined $1); # capture the file date fromt the name if configured in the reg exp
		 
		my $remoteTime = $ftp->mdtm($file); # get mod time 

		# Rename if required
		$localFileName = renameFile($cfgHashRef, $file);
		
		my $localFilePath; 
		# do daily mode processing 
		if ($cfgHashRef->{DAILY_DIR}) {
			myCroak ("Daily mode configured, but $file, dosn't have date portion in name, can't use daily dir mode") 
				if (!defined $fileDate);
			# need to create a daily dir for each file based on the files 
			# timestamp which is captured from the name
			if (! -e "$cfgHashRef->{LOCALDIR}/$fileDate") {
				mkdir ($cfgHashRef->{LOCALDIR}/$fileDate) || 
					myCroak ("Can't make daily dir $cfgHashRef->{LOCALDIR}/$fileDate: $!");
			}
			$localFilePath = "$cfgHashRef->{LOCALDIR}/$fileDate/$localFileName";
		}
		else {
			# Add the path
			$localFilePath = "$cfgHashRef->{LOCALDIR}/$localFileName";
		}
		
		# work out if we should fetch it
		if ( -e $localFilePath)
		{
			# we have it but check modification times to see if its changed
			my ($localTime) = (stat($localFilePath))[STAT_MOD_TIME_POS];
			next if ($localTime >= $remoteTime);
		}
	
		logInfo("Fetching file $file from system $sys, host $cfgHashRef->{HOST}, as file $localFilePath.");
		
		unless (defined $ftp->get($file, $localFilePath))
		{
			logError("Unable to fetch file $file from system $sys." .  $ftp->message());
			next;
		}
		# set mod time of local file to same as remote file
		utime $remoteTime, $remoteTime, $localFilePath;
	}
	$ftp->quit();
}

#####################################################################
## Function to perform file send                                    #
## param1 = system name from config file                            #
## param2 = Hash reference containing other fields from config file #
#####################################################################
sub sendFiles($$)
{
	my ($sys,$cfgHashRef) = @_;
	my $ftp ;
	my $remoteFileName;

	# create the connection	
	$ftp =  Net::FTP->new($cfgHashRef->{HOST}, Debug => $ftpDebug);

	unless (defined $ftp)
	{
		logError("Unable to connect to system $sys. $@");
		return;
	}
	
	# login
	unless($ftp->login($cfgHashRef->{USER}, $cfgHashRef->{PASSWORD})) 
	{
		logError("Unable to login to remote system $sys." .  $ftp->message());
		return;
	}
	
	# go to required remote directory
	unless($ftp->cwd("$cfgHashRef->{REMOTEDIR}"))
	{
		logError("Unable to change to remote dir for system $sys." .  $ftp->message());	
		return;
	}	

	# List local files, if dir can't be open then log error and return
	unless (opendir (LOCDIR, $cfgHashRef->{LOCALDIR})) {
		logError("Local directory '$cfgHashRef->{LOCALDIR}' dosn't exist for system $sys.");
		return;
	}
	
	# loop through the local files
	while (my $file = readdir(LOCDIR))
	{
		next unless ($file =~ /$cfgHashRef->{PATTERN}/); # skip files that don't match

		my $filePath = "$cfgHashRef->{LOCALDIR}/$file";
		my ($localTime) = (stat($filePath))[STAT_MOD_TIME_POS];
		
		# Rename if required
		$remoteFileName = renameFile($cfgHashRef, $file);
		
		# Add the path
		my $remoteFilePath = "$cfgHashRef->{REMOTEDIR}/$remoteFileName";
		
		# work out if we should send it by checking it exists and its mod time
		my ($remoteTime) = $ftp->mdtm($remoteFilePath);
		if (defined $remoteTime) {
			next if ($localTime < $remoteTime);
		}
	
		logInfo("Sending file $file, to host $cfgHashRef->{HOST}, file $remoteFileName.");
		
		unless($ftp->put($filePath, $remoteFilePath ))
		{
			logError("Unable to send file '$filePath', to remote file $remoteFileName." . $ftp->message());
			return;
		}
	}
	closedir(LOCDIR);
	$ftp->quit();
}

#####################
## MAIN PROCESSING ##
#####################

# Set the current date for logging
my ($day, $month, $year ) = ( localtime ) [3, 4, 5];
$lastLogDate = sprintf("%d-%02d-%02d", $year+1900,$month+1,$day);

# get the command line options 
getopt ('hd:c:s:m:',\%opts);
$sleepTime=$opts{"s"}      if (defined($opts{"s"})); 
$configFile=$opts{"c"}     if (defined($opts{"c"})); 
if (defined $opts{"m"}) {
	if ($opts{"m"} eq "GET" ) { $mode = MODE_GET; }
	elsif ($opts{"m"} eq "PUT" )  { $mode = MODE_PUT; }
	else { myCroak ("Mode must be PUT or GET" ); }		 
} 

if (exists($opts{"d"}))
{
	$debug=TRUE; 
	$ftpDebug=TRUE if (defined ($opts{"d"}) && $opts{"d"} == 1) ;
}

if (exists($opts{"h"}))
{
	usage();
	exit 0;
}

myCroak "Config file $configFile dosn't exist"   if (! -e $configFile);

# load the config
getConfig($configFile);

# Debug dump of the hash
if ($debug)
{
	for my $system (keys %cfgHash)
	{
		print "cfgHash{$system} = \n";
		print "  HOST = $cfgHash{$system}{HOST}\n";
		print "  USER = $cfgHash{$system}{USER}\n";
		print "  REMOTEDIR = $cfgHash{$system}{REMOTEDIR}\n";
		print "  LOCALDIR = $cfgHash{$system}{LOCALDIR}\n";
		print "  PATTERN = $cfgHash{$system}{PATTERN}\n";
		print "  RENAME = $cfgHash{$system}{RENAME}\n";
		print "  RENAME_PATTERN = $cfgHash{$system}{RENAME_PATTERN}\n";
	}
}


# Start main loop
while (TRUE)
{
	# Fetch Files from each system in turn
	for my $system (keys %cfgHash)
	{
		if ($mode == MODE_GET ) {
			logInfo ("Fetching Files from system $system");
			fetchFiles($system,$cfgHash{$system});
		}
		else {
			logInfo ("Sending Files from system $system");
			sendFiles($system,$cfgHash{$system});
		}
	}
	last if ($sleepTime eq 0);   # exit if only 1 fetch required

	# sleep until the next fetch
	logInfo ("Sleeping until next transfer in $sleepTime seconds");
	sleep ($sleepTime);			 
}

