#! /opt/perl/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use Image::Resize;


for my $file (<*_face.jpg>) {
	my $im = GD::Image->new($file);
	die "Failed to create image" if ! defined $im;
	my $rs = Image::Resize->new($im);
    $im = $rs->resize(40,60);
    open (OUTFILE, ">small/$file") || die "Failed to open file: $!";
	print OUTFILE $im->jpeg() || die "Failed to write file: $!";
}