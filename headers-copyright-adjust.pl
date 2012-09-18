#!/usr/bin/perl
#
# AUTHOR: Francesco Chemolli <kinkie@squid-cache.org> 
#
# Part of the Squid Web Cache project, licensed for use and distribution
# under the terms of the Squid Web Cache; please refer to the files COPYING
# and COPYRIGHT.
#
# 
# USAGE: headers-copyright-adjust.pl filename.h >filename.h.adjusted
#
# Purpose of this file is to make sure that copyright comments are inside the
# include-guard for headers, with the purpose of reducing intermediate
# data produced by the compiler. It expects an input file form with the blocks:
# [whitespace], C-style comment, [whitespace], include-guard, code
# and it turns that into:
# include-guard, one empty line, comment, one empty line, code
# files which do not respect this structure are copied verbatim, 
# modulo whitespace
# 
#
# Suggested usage:
# for file in $(find . -name \*.h); do /full/path/to/sort-includes.pl $file >$file.adj; mv $file.adj $file; done

use strict;
use warnings;

# we care only for files having this structure:
# optional whitespace (skipped)
# comment (initiated by /* and ended by */)
# optional whitespace (skipped)
# ifndef/define  (initiated by #ifndef, followed by #define)
# everything else
# if a file doesn't match this structure, we copy it verbatim to output

my @in=<>;
my @comment=();
my @ifdef=();
my $debug=0;

# skip whitespace
while (@in) {
  if ($in[0] =~ m!^\s*$!) {
    debug("ws");
    shift @in;
  } else {
    debug("end of ws");
    last;
  }
}
unless ($in[0] =~ m!/\*!) {
  debug("no comment");
  emit(@in);
  exit 0;
}
while (@in) {
  $_=shift @in;
  push @comment,$_;
  if (m!\*/!) { #end-of-comment
    debug("end of comment");
    last;
  }
}
# skip whitespace
while (@in) {
  if ($in[0] =~ m!^\s*$!) {
    debug("ws");
    shift @in;
  } else {
    debug("end of ws");
    last;
  }
}
unless ($in[0] =~ m!#ifndef!) {
  debug("no ifndef");
  emit(@comment);
  emit(@in);
  exit 0;
}
push @ifdef,shift @in;
push @ifdef,shift @in;

emit(@ifdef);
print "\n";
emit(@comment);
print "\n";
emit(@in);
exit 0;

sub emit {
  foreach (@_) {
    print;
  }
}

sub debug {
  return unless $debug;
  print STDERR $_[0];
  print STDERR "\n";
}
