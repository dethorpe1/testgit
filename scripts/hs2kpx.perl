#! /opt/perl/bin/perl -w

open (HS_FILE, "$ARGV[0]") || die "can't open file $ARGV[0]: $!";
open (KP_FILE, ">$ARGV[1]") || die "can't open file $ARGV[1]: $!";

my $ingroup=0;
my $incard=0;
my $comment;
print KP_FILE <<END;
<!DOCTYPE KEEPASSX_DATABASE>
<database>
END
while (<HS_FILE>) {
	chop $_;
	chomp $_;
	if ($_ =~ m/\[Category: (.*)\]/) {
		chomp $1;
		print "# Found Category: $1\n";
		print KP_FILE "<comment>$comment</comment>" if defined $comment;
		print KP_FILE "</entry>" if $incard == 1;
		print KP_FILE "</group>" if $ingroup == 1;
		chomp $1;
		print KP_FILE "<group><title>$1</title><icon>51</icon>";
		$ingroup=1;
		$incard=0;
		undef $comment;
	}
	elsif ($_ =~ /\[Card/) {
		my $card = <HS_FILE>; # take next line as title
		my($type,$title) = split(/: /, $card);
		chomp $title;
		chomp $title;
		print "  Found Card: $title\n";
		print KP_FILE "<comment>$comment</comment>" if defined $comment;
		print KP_FILE "</entry>" if $incard == 1;
		print KP_FILE "<entry>\n<title>$title</title><icon>0</icon>";
		$incard = 1;
		undef $comment;
	}
	elsif ($_ =~ /(Login|User|username): (.*)$/i ){
		chomp $2;
		print KP_FILE "<username>$2</username>";
	}
	elsif ($_ =~ /(Password): (.*)$/i ){
		chomp $2;
		print KP_FILE "<password>$2</password>";
	}
	elsif ($_ =~ /(URL|Url|url): (.*)$/ ){
		chomp $2;
		print KP_FILE "<url>$2</url>";
	}
	elsif ($_ ne "") {
		chomp $_;
		if ($incard == 1 ) {
			$comment .= "$_\n";
		}
	}
}
print KP_FILE "<comment>$comment</comment>" if defined $comment;
print KP_FILE "</entry>" if $incard == 1;
print KP_FILE "</group>" if $ingroup == 1;

print KP_FILE "</database>";
