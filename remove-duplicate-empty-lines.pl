#!/usr/bin/perl
#
# AUTHOR: Francesco Chemolli <kinkie@squid-cache.org> 
#
# Part of the Squid Web Cache project, licensed for use and distribution
# under the terms of the Squid Web Cache; please refer to the files COPYING
# and COPYRIGHT.
#
# 
# USAGE: remove-duplicate-empty-lines.pl file|dir [file|dir] ...
#
# Aim of this script is to reduce sets of duplicate empty lines
# onto a single empty line.
#
# will recurse into subdirectories and only handle files with 
#  .c, .h or .cci extensions

use strict;
use warnings;

#argument: filename
#  will check for duplicate empty lines in filename and remove them.
#  Will modify the file in-place.
sub handle_file {
  my $fh;
  my @out;
  my $filename=shift @_;
  my $el=0; #1 if last line was empty
  my $touched=0;

  print STDERR "$filename...";
  open ($fh,$filename) || die "can't open file $filename";

  while (<$fh>) {
    if (m!^\s*$!) {
      if ($el) {
        #skip a line
        $touched=1;
      } else {
        #first empty line, don't skip
        push @out,$_;
      }
      $el=1;
    } else {
      push @out,$_;
      $el=0;
    }
  }
  close $fh;

  if ($touched) {
    open $fh,">$filename" || die "can't open file $filename for writing";
    print $fh @out;
    close $fh;
    print STDERR " Modified\n";
  } else {
    print STDERR "\r";
  }
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

if ($#ARGV < 0) { #no arguments
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
