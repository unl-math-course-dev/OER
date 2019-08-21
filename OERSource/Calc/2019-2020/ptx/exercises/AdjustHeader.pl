#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp qw(read_file write_file);

my @files = <*.xml>;
foreach my $file (@files){

my $filename = $file;
$filename =~ s/\.xml/.xml/g;

#print $filename;
#print "\n";

my $data = read_file $file, {binmode => ':utf8'};


 $data =~ s/[^[:ascii:]]//g;


  $data =~ s/<!-- Copyright(?s)(.*)Boelkins/<!-- Copyright 2019                                                        -->\n<!-- UNL Department of Mathematics                                         -->\n<!-- Based upon the work of                                                -->\n<!-- Matthew Boelkins                                                      -->\n<!-- Copyright 2012-2018                                                   -->/gs;
  $data =~ s/<!-- This file is part of Active Calculus.                                 -->/<!-- This file is part of Coordinated Calculus.                            -->\n<!-- This file is based on Active Calculus.                                -->/gs;







  




write_file $filename, {binmode => ':utf8'}, $data;
print "modified header\n";
print $filename;
}

#Invoke with perl FormatV2.pl *.txt

print "\n";