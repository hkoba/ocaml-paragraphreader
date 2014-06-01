#!/usr/bin/env perl
# -*- coding: utf-8 -*-
use strict;
use warnings FATAL => qw/all/;

my ($nPars, $nLineChars, $nLines, $nSepChars) = @ARGV;

for (1 .. KMG($nPars // 10)) {
  print "A" x KMG($nLineChars // 1), "\n" for 1 .. KMG($nLines // 8);
  print "\n" x KMG($nSepChars // 2);
}

sub KMG {
  my ($val) = @_;
  if ($val =~ s/K$//) {
    $val * 1024
  } elsif ($val =~ s/M$//) {
    $val * 1024 * 1024
  } elsif ($val =~ s/G$//) {
    $val * 1024 * 1024 * 1024
  } else {
    $val
  }
}
