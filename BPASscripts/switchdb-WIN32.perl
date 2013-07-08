#! c:\perl\bin\perl.exe

# Script to switch the BPAS Database ODBC and catalyst settings between the 
# master (linux server) and slave (windows laptop) DBs.

use strict;
use warnings;
use Win32::TieRegistry ( TiedHash => '%RegHash' );

my $Registry= \%RegHash;
my %choices = ( 1 => "dtserver01", 
				2 => "dtrock01" );
my $catFile= "C:\\home\\craign\\eclipse\\workspace\\cat_bpas\\cat_bpas.conf";

# Get the user to make a selection

print "Which BPAS DB do you want to set the ODBC connection to?\n";
while (my ($key,$value) = each (%choices)) {
	print " $key) $value\n";
}
print "> ";

my $key = <STDIN>;
chomp $key;

die "Invalid selection: $key" unless (exists $choices{$key});

# Modify the ODBC setting in the registry

print <<END;

==> Setting ODBC connection to system '$choices{$key}'

#################
WARNING: In MS Access if existing tables where originally linked
         with a server different to the one selected then you need 
         to map a new link table with the ODBC link before the changed 
         server will take effect.
#################
END

$Registry->{"HKEY_LOCAL_MACHINE\\SOFTWARE\\ODBC\\ODBC.INI\\BPASMembership\\SERVER"} = $choices{$key};

# Change the server in the catalyset config

print "\n==> Setting catalyst config to system '$choices{$key}'\n";

$^I='~'; # set in place editing
push @ARGV, $catFile;
while (<>) {
	if (m/(^.*connect_info.*host=).*$/) {
		print "$1" . "$choices{$key}\n";
	}
	else { 
		print
	}  
}


