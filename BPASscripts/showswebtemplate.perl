#! /opt/perl/bin/perl -w
#
# Script to generate BPAS shows web page directly from database
# Will work as CGI or as command line script. If command line writes to file 
# defined in variables below, otherwise writes to STDOUT for CGI
# 
use strict;
use Carp;
use CGI qw/:standard *center *table *Tr *td/;
use DBI;
use bpas;
# use Win32;
use HTML::Template;


# set debug mode
my ($debug) = (0);

# locations of files
my ($dbConnect,$outputDir, $outputFile,$templateFile) = (
	"DBI:ODBC:BPASMembership",	
	#"$ENV{MY_DOCUMENTS}\\BPAS\\membership details\\membership database",
	$ENV{'BPAS_WEBSITE_DIR'},	
	"ShowList.htm",
	"$ENV{MY_DOCUMENTS}\\eclipse\\workspace\\BPASscripts\\ShowList_template.htm");
	
# create the template
my $tmpl = new HTML::Template (filename => $templateFile, die_on_bad_params => 0 , global_vars => 1, debug => 0 );
my @shows = (); # array of show info
my $showidlist = ""; # list of show ids as string for javascript in template

#my $showStatement = qq(SELECT ShowID, ShowName, Location,StartDate, EndDate,
#							  StartTime, EndTime,Confirmed,ShowDescription,
#							  KitRequired,OrganiserDetails,BPASshow, FORMAT (StartDate,'ddd'), FORMAT (EndDate, 'ddd' )
#				 	 FROM Shows
#					 ORDER BY StartDate);

my $showStatement = qq(SELECT ShowID, ShowName, Location,StartDate, EndDate,
							  StartTime, EndTime,Confirmed,ShowDescription,
							  KitRequired,OrganiserDetails,BPASshow, DATE_FORMAT(StartDate,'%e/%c/%Y'), DATE_FORMAT(EndDate, '%e/%c/%Y' )
				 	 FROM Shows
					 ORDER BY StartDate);
					 
my $linksStatement = qq(SELECT ShowLinks.Link, ShowLinks.LinkName 
						FROM ShowLinks
						WHERE ShowId = ? 
						ORDER BY Link);
	
# global html values
# NOTE: Add col3width to tablewidth if 3rd col for attendance used
# with attendance colimne - $tmpl->param ( backColor => "#40878E", tableWidth=>"790", col1Width=>"90", col2Width=>"590",col3Width=>"110");
$tmpl->param ( backColor => "#40878E", tableWidth=>"*", col1Width=>"90", col2Width=>"*");

my (%months) = ( "01" => "Jan",
				 "02" => "Feb",
				 "03" => "Mar",
				 "04" => "Apr",
				 "05" => "May",
				 "06" => "Jun",
				 "07" => "Jul",
				 "08" => "Aug",
				 "09" => "Sep",
				 "10" => "Oct",
				 "11" => "Nov",
				 "12" => "Dec" );

my (@dayArray) = qw/Sat Sun Mon Tue Wed Thu Fri/;
my (%dayHash) = ( Sat=>0,
				  Sun=>1,
				  Mon=>2,
				  Tue=>3,
				  Wed=>4,
				  Thu=>5,
				  Fri=>6 );
my $maxDayNum = 6;
	   
my (%ind) = ( -1 => "YES",
			  1 => "YES",
			  0 => "NO");
my ($linksSth,$bCGI);
		 
########################################################
# subroutine to handle special chars:
#   Replace \n with <BR>
########################################################
sub processSpecial($)
{
	local $_ = $_[0];
	$_ =~ s#\n#<BR>#g;
	$_ =~ s#\r##g;
	return $_
}

####################################
# subroutine to write the top, fixed, bit of the web page
####################################
sub WebHeader()
{
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $genDate = $mday . "/" . ($mon+1) . "/" . ($year+1900);
DbgPrint ("WEB HEADER\n");
$tmpl->param ( gendate => $genDate );

}

###########################################
# Subroutine to produce list of valid days  
###########################################
sub AddDayEntries
{
	my ($day,$dayArrRef, $arriveArrRef) = @_;
	
	my %dayHash = ( dayname => $dayArray[$day], daynumber => "$day");
	push @$dayArrRef, \%dayHash;
	push @$arriveArrRef, { arrtext => "$dayArray[$day] morn" , arrnum => 1}; 
	push @$arriveArrRef, { arrtext => "$dayArray[$day] after", arrnum => 2 }; 
	push @$arriveArrRef, { arrtext => "$dayArray[$day] even" ,  arrnum => 3 }; 
	DbgPrint ("Adding day: $dayArray[$day] - $day\n");
}

sub ShowDays($$)
{
	my ($sDay,$eDay) = @_;
	my @days = ();
	my @arrive = ();
	# Days are Ddd
	
	$eDay = $sDay unless ( defined $eDay ); # no end date

	# Look up start and end days in hash to get numbers
	my $sNum = $dayHash {$sDay};
	my $eNum = $dayHash {$eDay};
		
	# go through the numbers adding day details to the array to return
	my $i;
		
	if ( $sNum <= $eNum )
	{
		for ($i = $sNum; $i <= $eNum; $i++)
		{
			AddDayEntries($i, \@days, \@arrive );
		}
	}
	else
	{
		# loop from start day until end of list of days
		for ($i = $sNum; $i <= $maxDayNum; $i++)
		{
			AddDayEntries($i, \@days, \@arrive );
		}
		# loop from start of day list until end day
		for ($i = 0; $i <= $eNum; $i++)
		{
			AddDayEntries($i, \@days, \@arrive );
		}
	}
	
	return \@days, \@arrive;
}


#####################################################
# Subroutine to write a show record to the web page
#####################################################

sub WebRecord($)
{
	my ($showArr) = shift;
	my ($sD,$eD,$sT,$eT,$dummy,$formatedDate);
	my ($id, $name, $location, $startDate,$endDate,$startTime,$endTime,
	    $confirmed, $description,$kit,$Organiser,$bpasShow,$startDay, $endDay) = (@$showArr);
	
	DbgPrint("Writing record for showid [$id], name [$name]\n");

	### Show header Row ###

	# Dates are YYYY/MM/DD, Times are HH:MM:SS
	($sD,$dummy) = split(/ /,$startDate);	# ignore time portion
	($eD,$dummy) = split(/ /,$endDate);	    # ignore time portion
    ($dummy,$sT) = split(/ /,$startTime) if ($startTime) ;	# ignore Date portion
    ($dummy,$eT) = split(/ /,$endTime) if ($endTime) ;		# ignore Date portion

	### Show title row ###
	if ($sD eq $eD)
	{
		$formatedDate = substr($sD,8,2) . " " . $months{substr ($sD,5,2)};
	}
	else 
	{
		$formatedDate = substr($sD,8,2) . "-" . substr ($eD,8,2) . " " . $months{substr ($sD,5,2)};
	}
	
	### Dates & Flags row ###

	# format date for display
	my $formatedStart = join ("/", substr ($sD,8,2),substr ($sD,5,2),substr ($sD,0,4)) . " "; 
	my $formatedEnd   = join ("/", substr ($eD,8,2),substr ($eD,5,2),substr ($eD,0,4)) . " "; 

	# add time portion if defined
	$formatedStart .=  substr($sT,0,5) if ($startTime);
	$formatedEnd   .=  substr($eT,0,5) if ($endTime);

	## Add list of days
	my ($daysArrayRef, $arriveArrayRef); 
	# ($daysArrayRef, $arriveArrayRef) = ShowDays ($startDay, $endDay );
	
	### Location Row ###
	$location = processSpecial($location);
	
	### Description Row ###
	$description = processSpecial($description);

	### Links Row ###
	my $linksArrayRef = webLinks($id);

	# set up the hash for the show
	my %showHash = (
		showid => $id,
		showdate => $formatedDate,
		showname => $name,
		startDate => $formatedStart,
		enddate => $formatedEnd,
		bpasind => $ind{$bpasShow},
		confirmedind => $ind{$confirmed},
 		location => $location,
		description => $description,
		links => $linksArrayRef,
		days => $daysArrayRef,
		arrive => $arriveArrayRef
	);
	
	# add the show hash to the array for the template
	push @shows, \%showHash;

	# build up the show id list
	$showidlist .= "," if ($showidlist);  # add comma if not empty
	$showidlist .= "\"" . $id . "\"";
	
}

#####################################################
# subroutine to write the links for a show to its table
# row on the web page
#####################################################

sub webLinks ($)
{
	my ($id) = shift;
	my ($text,$href);
	my @linksArray = ();

	# look up all links for this show id and write to web page
	# write each link on seperate line in same cell
	
	# get the links for the show
	$linksSth->bind_param(1,$id); 	# bind this show to the links statement (gloablly prepared previously)
	$linksSth->execute(); 			# execute the links query for this show
	
	# iterate over rows and write to web
	while (my $linksArr = $linksSth->fetchrow_arrayref())
	{
		DbgPrint ("Found link for show [$id]: @$linksArr\n");
		#($text,$href) = split (/#/, @$linksArr[0]);
		push @linksArray, {href => @$linksArr[0], text => @$linksArr[1]};
	}
	return \@linksArray;
}

############################
# START OF MAIN PROCESSING #
############################

SetDebug($debug);

# get output dir from environment

if (!defined ($outputDir))
{
	croak "BPAS_WEBSITE_DIR environment variable not defined";
}

# connect to the database
my $dbh = DBI->connect($dbConnect, "", "", {PrintError=>0, RaiseError=>1});
          
# set required params for the DB
$dbh->{LongReadLen} = 10000;
$dbh->{FetchHashKeyName} = 'NAME_lc';

# work out required output. If running as CGI then use stdout
# otherwise use configured output file
$bCGI = SetOut("$outputDir\\$outputFile");

DbgPrint "\nConnected\n";

# prepare the main show query and the links query 
my $showSth = $dbh->prepare ( $showStatement ) ;
$linksSth = $dbh->prepare ( $linksStatement ) ; # prepared once then use globally

#execute the show query
$showSth->execute() ;

# get all the shows
my $showArr = $showSth->fetchall_arrayref();

# now go through show list and create web table
DbgPrint("BEGINNING WEB OUTPUT:\n");

WebHeader();

foreach (@$showArr)
{
	WebRecord($_);
}

# pass array of show details to the template
$tmpl->param (showidlist => $showidlist );
$tmpl->param (shows => \@shows);

DbgPrint ("Show id list : $showidlist\n" );

# print the template
PrintWeb ($tmpl->output);

CloseOut();

if (!$bCGI)
{
	# Copy page to PDA
	CopyToPda("$outputDir\\$outputFile");
#	Win32::MsgBox("### Web page '$outputDir\\$outputFile' generated ###",MB_ICONINFORMATION,"Show List Finished");
	my $key;
	print "### Web page '$outputDir\\$outputFile' generated\n### Press ENTER to exit";
	read STDIN, $key, 1
}
