#!/usr/bin/perl

#Load the perl packages we need in order to make the changes.
use strict;
use warnings;
use File::Slurp qw(read_file write_file);


#Load all files in the folder that end in .xml
my @files = <*.xml>;

#Loop through each file one by one
foreach my $file (@files){

#Capture the file name and change the extension if desires.  In this particular instance we keep the file extension.
my $filename = $file;
$filename =~ s/\.xml/.xml/g;

#Read in the contents of the file using unicode
my $data = read_file $file, {binmode => ':utf8'};

#Strip out and data that is not ascii
 $data =~ s/[^[:ascii:]]//g;
 
#Define the expression that we are searching for 
my $regex = qr/<subsection><title>Exercises<\/title>(.*?)<\/subsection>/sp;
 #If then condition.  Is the expression present in the file?
 if ($data =~ /$regex/g )
 {
 #If the expression is present then we replace the expression with our new expression
   $data =~ s/<subsection><title>Exercises<\/title>(.*?)<\/subsection>/<exercises xmlns:xi=\"http:\/\/www.w3.org\/2001\/XInclude\"> $1 <\/exercises>/gs;

  print "Changed "; 
  print " ";
  print $filename;
  print "\n";
  }
  else
{ 
#If the expression is missing then we say nothing needs to be done.
 print " ";
  print "No need to change"; 
  print " ";
  print $filename;
  print "\n";
 }

  



#Write the new contents into the file.
write_file $filename, {binmode => ':utf8'}, $data;
}
print "Completed the Repair Task\n";

print "\n";
