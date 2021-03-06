#! /opt/perl/bin/perl -w

#
# Script to generate BPAS attendance web page directly from database
# Will work as CGI or as command line script. If command line writes to file 
# defined in variables below, otherwise writes to STDOUT for CGI
# 
# NO LONGER USED - REPLACED WITH CATALYST APP #

use DBI;
use strict;
use CGI qw/:standard *table *center/;
use Carp;
use bpas;
#use Win32;

my ($dbConnect,$outputFile,$debug ) = 
	("DBI:ODBC:BPASMembership", 
	 "AttendList.htm",
	 0);
my $showStatement = qq(SELECT ShowID, ShowName, StartDate, EndDate
				 	 FROM Shows
					 ORDER BY StartDate);
#my $attendStatement = "
#	SELECT DISTINCTROW 	MemberShows.Notes, MemberShows.ExpectedArrival, 
#					MemberShows.PlannedAttendance, MemberShows.PlannedDays, 
#						Membership.Name, Membership.No, Membership.Commandary, Membership.[Character name] 
#	FROM Membership RIGHT JOIN MemberShows 
#		 ON Membership.No = MemberShows.MembershipNo 
#	WHERE  MemberShows.ShowID = ? 
#	ORDER BY Membership.Name";
my $attendStatement = "
SELECT DISTINCTROW 	MemberShows.Notes, MemberShows.ExpectedArrival,
					MemberShows.PlannedAttendance, MemberShows.PlannedDays,
					Membership.Name, Membership.No, Membership.Commandary,
            		Membership.`Character name`
	FROM Membership, MemberShows
	WHERE  MemberShows.ShowID = ? AND
         Membership.No = MemberShows.MembershipNo
	ORDER BY Membership.Name";

# global html values
my ($bgColor,$tableWidth,$col1Width,$col2Width,,$col3Width,,$col4Width,,$col5Width,$col6Width,$showTitleFontCol,$listTitleFontCol) = 
		("#40878E",
		 "*",
		 "110",
		 "86",
		 "92",
		 "108",
		 "*",
		 "110",
		 "#800000",
		 "#000080");
my %tableAlign = (align=>"left", 
				  valign=>"top");
my %col1 = (width=>$col1Width);
my %col2 = (width=>$col2Width);
my %col3 = (width=>$col3Width);
my %col4 = (width=>$col4Width);
my %col5 = (width=>$col5Width);
my %col6 = (width=>$col6Width);

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

my ($bCGI, $attendSth, $out, $key);

####################################
# subroutine to write the top, fixed, bit of the web page
####################################
sub WebHeader()
{
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $genDate = $mday . "/" . ($mon+1) . "/" . ($year+1900);

DbgPrint "WEB HEADER\n";
PrintWeb (start_html({-title=>"BPAS shows Attendance list 2008", 
					   -stylesrc=>"index.htm",
					   -background=>"BPASbackground.jpg",
					   -style=>{'src'=>'bpasstyles.css'},
						meta=>{GENERATOR=>'perl CGI',
                               keywords=>'generated by perl',
					   		   description=>'BPAS shows attendance list 2008. 
Generated using perl::DBI to extract data from an MS Access database and perl::CGI to generate the web page.
(Craig Nicholas, Dethorpe Ltd, 2007)'}}));

# BPAS header and page description
PrintWeb (<<END
<p align="center"><a href="index.htm" target="_parent"><img src="images/BPASbanner.jpg"
alt="BPAS banner [Click to go to home page]" border="0" WIDTH="688" HEIGHT="85"></a></p>

<p align="center"><a name="shows"></a><h1 class=center>2008 Show Attendance<small> (Generated $genDate)</small></h1></p>

<p align="center">This page contains a list shows, and for each show
the members who have confirmed they are attending. This feature is an aid to members and
organisers in arranging shows, any comments or suggestions welcome.</p>
END
);

# Start of attendance table
PrintWeb ( start_center(),
		   start_table({border=>"1",bgcolor=>"#FFFFFF",cellspacing=>"0",bordercolor=>$bgColor,width=>$tableWidth}));

}

####################################
# subroutine to write the bottom, fixed, bit of the web page
####################################
sub WebFooter()
{
	DbgPrint "WEB FOOTER\n";
	# end of shows table
	PrintWeb (end_table());
	
	# generated by perl footer
	PerlFooter($tableWidth);

	PrintWeb (end_center(),end_html());
}

#####################################################
# Subroutine to write an attendance record to the web page
#####################################################

sub WebRecord($)
{
	my ($recArr) = shift;
	# set blank fields to a non-breaking space (&nbsp;)
	foreach (@$recArr)
	{
		unless ($_) { $_ = "&nbsp;"; }
	}
	my ($notes, $expArrival, $planAttend, $planDays, $name, $no, $commandary, $charName ) = @$recArr;
	$notes =~ s/\n/<BR>/g; # replace CRs with HTML <BR> tag

	# reduce surname to 1st 2 chars for data protection and privacy
	my @nameSplit = split (/ /,$name);
	$nameSplit[$#nameSplit] = substr($nameSplit[$#nameSplit],0,2);
	$name = join (" ", @nameSplit);
	
	DbgPrint ("ATTEND RECORD: $notes, $expArrival, $planAttend, $planDays, $name, $no, $commandary, $charName \n" );
		
	PrintWeb ( Tr(\%tableAlign,
					td(\%col1,font({size=>"1"},$name)),"\n",
					td(\%col2,font({size=>"1"},$commandary)),"\n",
					td(\%col3,font({size=>"1"},$planDays)),"\n",
					td(\%col4,font({size=>"1"},$expArrival)),"\n",
					td(\%col5,font({size=>"1"},$notes)),"\n",
					td(\%col6,font({size=>"1"},$charName)),"\n"
				 ),"\n"
			  );
}

#####################################################
# Subroutine to write header for a show in the attendance list 
#####################################################

sub WebShowHeader($$$$)
{
	my ($id, $name,$start,$end) = @_;
	my ($nameWidth) = "*"; # $col2Width + $col3Width + $col4Width + $col5Width + $col6Width;
	my ($sD,$eD,$sT,$eT,$dummy,$formatedDate);
	
	DbgPrint "SHOW HEADER: $id, $name, $start, $end\n";
	
	# Dates are YYYY-MM-DD, Times are HH:MM:SS
	($sD,$dummy) = split(/ /,$start);	# ignore time portion
	($eD,$dummy) = split(/ /,$end);	    # ignore time portion
	
	if ($sD eq $eD)
	{
		$formatedDate = substr($sD,8,2) . " " . $months{substr ($sD,5,2)};
	}
	else 
	{
		$formatedDate = substr($sD,8,2) . "-" . substr ($eD,8,2) . " " . $months{substr ($sD,5,2)};
	}

	# Show header line	
	PrintWeb (
			Tr(
				td({width=>$col1Width,bgcolor=>$bgColor},font({color=>$showTitleFontCol, size=>"4"},u(b($formatedDate)))),"\n",
				td({width=>$nameWidth,bgcolor=>$bgColor,colspan=>"5"},font({color=>$showTitleFontCol, size=>"4"},u(b($name)))),"\n"
			   ),"\n"
			 );
	# column headers
	PrintWeb (
			Tr(
				td(\%col1,font ({size=>"2",color=>$listTitleFontCol},b("Name"))),"\n",
				td(\%col2,font ({size=>"2",color=>$listTitleFontCol},b("Commandrie"))),"\n",
				td(\%col3,font ({size=>"2",color=>$listTitleFontCol},b("Planned Days"))),"\n",
				td(\%col4,font ({size=>"2",color=>$listTitleFontCol},b("Expected Arrival"))),"\n",
				td(\%col5,font ({size=>"2",color=>$listTitleFontCol},b("Notes"))),"\n",
				td(\%col6,font ({size=>"2",color=>$listTitleFontCol},b("Character Name"))),"\n"
			   ),"\n"
			  );

 }
#####################################################
# Subroutine to process a show
#####################################################

sub processShow($)
{
	my ($showArr) = shift;
	my ($showId, $ShowName, $StartDate, $EndDate) = (@$showArr);

	WebShowHeader($showId, $ShowName, $StartDate, $EndDate); # write out the show header to the web page

	# Now get the attendance for the show
	$attendSth->bind_param(1,$showId); 	# bind this show to the attendance statement (gloablly prepared previously)
	$attendSth->execute(); 				# execute the attendance query for this show
	
	# iterate over rows and write to web
	while (my $attendArr = $attendSth->fetchrow_arrayref())
	{
		WebRecord($attendArr); # $attendArr is array ref to row
	}
	
}

########################
# MAIN PROCESSING
########################

SetDebug($debug); #set debug level
# get output dir from environment
my $outputDir = $ENV{'BPAS_WEBSITE_DIR'};
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

# prepare the main show query and the attendance query 
my $showSth = $dbh->prepare ( $showStatement ) ;
$attendSth = $dbh->prepare ( $attendStatement ) ; # prepared once then use globally

#execute the show query
$showSth->execute() ;

# get all the shows
my $showArr = $showSth->fetchall_arrayref();

# write out the webpage header
WebHeader();

# iterate over the shows
foreach my $show (@$showArr)
{
	processShow($show); # $show is reference to an array containing the row
}

#write the web page footer
WebFooter();

CloseOut();
 
if (!$bCGI)
{
	# Copy page to PDA
	CopyToPda("$outputDir\\$outputFile");

#	Win32::MsgBox("### Web page '$outputDir\\$outputFile' generated ###",MB_ICONINFORMATION,"Attend List Finished");	
	print "### Web page '$outputDir/$outputFile' generated\n### Press ENTER to exit";
	read STDIN, $key, 1
}

