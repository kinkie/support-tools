#!/usr/bin/perl

#sort include lines according to squid's conventions.
# will recurse from the specified directory (current if unspecified)
# and check .h, .cc and .cci files

use strict;
use warnings;

sub handle_file {
	my $filename=shift @_;
	my $fh;
	my @out;
	my $touched=0;

	print STDERR "$filename...";
	open ($fh,$filename) || die "can't open file $filename";

	my @acc=();
	while (<$fh>) {
		if (m!^#include "!) {
			if (m!squid.h!) {
				push @out,$_;
			} else {
				push (@acc,$_);
				$touched=1;
			}
		} else {
			push @out, sort {lc($a) cmp lc($b)} @acc;
			@acc=();
			push @out,$_;
		}
	}
	close $fh;
	if ($touched) {
		open ($fh, ">$filename");
		print $fh join ("",@out);
		close ($fh);
	}
	print STDERR "\r";
}

#argument: dirname
# will call handle_file for all files in all subdirectories of the argument
# that have a .cc, .cci or .h suffix and don't begin with a dot.
sub handle_dir {
	my $dh;
	my $dirname=shift @_;
	opendir($dh,$dirname) || die "can't open dir $dirname";
	my @dir=readdir($dh);
	closedir($dh);
	my @files=grep { -f "$dirname/$_" && !/^\./ && /\.(h|cci?)$/ } @dir;
	my @dirs=grep { -d "$dirname/$_" && !/^\./ } @dir;

	foreach (@files) {
		&handle_file("$dirname/$_");
	}
	foreach (@dirs) {
		&handle_dir("$dirname/$_");
	}
}

if ($#ARGV < 0) {
	push @ARGV, ".";
}
foreach (@ARGV) {
  if (-d $_) {
    &handle_dir($_);
    next;
  }
  if (-f $_) {
    &handle_file($_);
    next;
  }
}
