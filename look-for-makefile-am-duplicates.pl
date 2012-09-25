#!/usr/bin/perl

#read in a Makefile.am.
# take out duplicate lines in each section
# Sections are identified by _SOURCES\s*=
while (<>) {
  unless (/_SOURCES\s*=/) {
    print;
    next;
  }
  print;
  while (<>) { #this is a SOURCES section
    next if exists ($sources{$_});
    $sources{$_}=1;
    print;
    last unless (/\\$/);
  }
  %sources=();
}
