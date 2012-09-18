#!/usr/bin/perl
#
# AUTHOR: Francesco Chemolli <kinkie@squid-cache.org> 
#
# Part of the Squid Web Cache project, licensed for use and distribution
# under the terms of the Squid Web Cache; please refer to the files COPYING
# and COPYRIGHT.
#
# 
# USAGE: remove-duplicate-empty-lines.pl filename.h >filename.h.adjusted
#
# Aim of this script is to reduce sets of duplicate empty lines
# onto a single empty line.
#
# Suggested usage:
# for file in $(find . -name \*.h -or -name \*.cc -or -name \*.cci); do echo $file; /full/path/to/remove-duplicate-empty-lines.pl $file >$file.adj; mv $file.adj $file; done

use strict;
use warnings;
my $el=0; #1 if last line was empty

while (<>) {
  if (m!^\s*$!) {
    unless ($el) {
      print;
    }
    $el=1;
  } else {
    print;
    $el=0;
  }
}
