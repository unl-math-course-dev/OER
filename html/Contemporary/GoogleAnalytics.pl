#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp qw(read_file write_file);

my @files = <*.html>;
foreach my $file (@files){

my $filename = $file;
$filename =~ s/\.html/.html/g;

print $filename;
print "\n";

my $data = read_file $file, {binmode => ':utf8'};


 $data =~ s/[^[:ascii:]]//g;

 if ($data =~ m/UA-122864107-1/)
 {
  #print "found the tracking code already present\n"; }
  else
{ 
  $data =~ s/<head>/<head>\n<script async src=\"https:\/\/www.googletagmanager.com\/gtag\/js?id=UA-122864107-1\"><\/script> <script> window.dataLayer = window.dataLayer \|\| \[\]; function gtag(){dataLayer.push(arguments);} gtag(\'js\', new Date()); gtag(\'config\', \'UA-122864107-1\');<\/script>/gs;
#print "added the tracking code\n";

 }






  




write_file $filename, {binmode => ':utf8'}, $data;
}
#print "added the tracking code\n";
#Invoke with perl FormatV2.pl *.txt


