#!/usr/bin/env perl
# -*- coding: utf-8 -*-
use strict;
use warnings FATAL => qw/all/;

my ($nPars, $nParChars, $nSepChars) = @ARGV;
print "A" x ($nParChars // 1), "\n" x ($nSepChars // 2) for 1 .. ($nPars // 10);
