package bpas;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(PerlFooter SetDebug DbgPrint PrintWeb SetOut GetOut CloseOut CopyToPda);
our @VERSION = 1.00;

use CGI qw(:standard *center);
use Carp;
use File::Copy;

my $debug =0;
my ($out, $bCGI);
my $pdaDir = $ENV{'PDA_DIR'};

########################################################
# Subroutine to set debug state
########################################################
sub SetDebug($)
{
	$debug = shift;
}

########################################################
# Subroutine to write debug messages to STERR if enabled
########################################################
sub DbgPrint($)
{
	print (STDERR "### DEBUG:".  $_[0]) if ($debug == 1);
}

########################################################
# Subroutine to write 'generated by perl' footer 
########################################################
sub PerlFooter (;$)
{
	my ($width) = @_;
	
	# generated by perl footer
	print $out start_center();
	if ( defined $width) {
		print $out p({align=>"center"},img({src=>"images/marble_bar.gif",width=>$width,height=>"12"})); }
	else {
		print $out p({align=>"center"},img({src=>"images/marble_bar.gif",height=>"12"})); }

	print $out small(strong("Generated with perl - Craig Nicholas, Dethorpe Ltd, 2007<BR>"));
	print $out a({href=>"http://www.perl.com"},
			 img({src=>"images/powered_by_perl.gif",alt=>"generated by perl",border=>"0",WIDTH=>"122",HEIGHT=>"55"})
	 	    );
	print $out end_center();
}



########################################################
# Subroutine to return the current output handle
########################################################
sub GetOut()
{
	return $out;
}

########################################################
# Subroutine to set the output to file or STDOUT depending
# on whether we are running as a CGI script or not
########################################################
sub SetOut($)
{
	$outFile = shift;
	# work out required output. If running as CGI then use stdout
	# otherwise use configured output file
	if (defined $ENV{'REQUEST_METHOD'})
	{	
		# We're running in CGI
		 $bCGI = 1;
		 $out = \*STDOUT;
		 DbgPrint(" Runing in CGI, setting output to STDOUT\n");
		 print $out header("text/html");
	}
	else
	{
		# we're running locally
		$bCGI = 0;
		open ( $out , ">$outFile" ) || 
				croak "ERROR: unable to open output file - $outFile\n" ; 
		DbgPrint(" Not Runing in CGI, setting output file\n");
	}
	return $bCGI; # return indicator of current output method
}

########################################################
# Subroutine to close the output file
########################################################
sub CloseOut()
{
	close $out unless ($bCGI);
}

########################################################
# Subroutine to print list of input parameters 
# to configured output
########################################################
sub PrintWeb
{
		if ($out) 
		{
			foreach (@_) {print $out $_ };
			return 1;
		}
		else
		{
			carp "WARNING: output not defined, call SetOut before 1st use of PrintWeb\n";
			return 0;
		}
}

########################################################
# Subroutine to copy file to BPAS PDA directory
# return 0 on failure, 1 on success
########################################################
sub CopyToPda($)
{
	my $filePath = shift;
	my @pathComp = split(/\\/, $filePath);
	my $file = $pathComp[$#pathComp];

	if ($pdaDir)
	{
		DbgPrint("Copying File '$filePath' to PDA\n");
	
		if (!copy ($filePath, "$pdaDir\\$file"))
		{ 
			carp "Failed to Copy file '$filePath' to PDA dir '$pdaDir\\$file'\n";
			return 0;
		}
	}
	else
	{
		DbgPrint("PDA_DIR environment variable not set, skipping copy to pda\n");
	}

	return 1;
}

1;
