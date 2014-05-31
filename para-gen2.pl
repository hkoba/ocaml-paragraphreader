#!/usr/bin/env perl
# -*- coding: utf-8 -*-
use strict;
use warnings FATAL => qw/all/;

my ($nPars, $nLineChars, $nLines, $nSepChars) = @ARGV;
for (1 .. ($nPars // 10)) {
  print "A" x ($nLineChars // 1), "\n" for 1 .. ($nLines // 8);
  print "\n" x ($nSepChars // 2);
}

