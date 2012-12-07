#!/usr/bin/perl

#sort include lines according to squid's conventions

my @acc=();
while (<>) {
  if (m!^#include "!) {
    if (m!squid.h!) {
      print;
    } else {
      push (@acc,$_);
    }
  } else {
    print sort {lc($a) cmp lc($b)} @acc;
    @acc=();
    print;
  }
}
