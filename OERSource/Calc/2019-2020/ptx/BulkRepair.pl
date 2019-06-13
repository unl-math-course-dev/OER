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
my $regex = qr/<subsection><title>Exercises<\/title>(.*?)<\/subsection>/sp;
 if ($data =~ /$regex/g )
 {
   $data =~ s/<subsection><title>Exercises<\/title>(.*?)<\/subsection>/<exercises xmlns:xi=\"http:\/\/www.w3.org\/2001\/XInclude\"> $1 <\/exercises>/gs;
#print $data;
 #print " ";
  print "Changed "; 
  print " ";
  print $filename;
  print "\n";
  }
  else
{ 
#print "added the tracking code\n";
 print " ";
  print "No need to change"; 
  print " ";
  print $filename;
  print "\n";
 }

  




write_file $filename, {binmode => ':utf8'}, $data;
}
print "Completed the Repair Task\n";

print "\n";
