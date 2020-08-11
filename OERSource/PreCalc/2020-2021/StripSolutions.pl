#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp qw(read_file write_file);
use File::Find::RULE;


my @files = File::Find::Rule->file->name("*.pg")->in(".");
my $list = "";
foreach my $file (@files){

my $filename = $file;


print $filename;
print "\n";

my $data = read_file $file, {binmode => ':utf8'};


 $data =~ s/[^[:ascii:]]//g;

 if ($data =~ m/BEGIN_SOLUTION/)
 {
 my $old = $filename;
 print $filename;
 print "\n Solution found, fixing file \n";
 $filename =~ s/\.pg/JustHint.pg/g;
  $data =~ s/BEGIN_SOLUTION.*?END_SOLUTION//gs;
$list = $list." ".$old." "."->"." ".$filename."\n";
  }
 if ($data =~ m/SOLUTION\(EV3\(\<\<\'END_SOLUTION\'\)\)/)
 {
 my $old = $filename;
 print $filename;
 print "\n Solution found, fixing file \n";
 $filename =~ s/\.pg/JustHint.pg/g;
  $data =~ s/SOLUTION\(EV3\(\<\<\'END_SOLUTION\'\)\).*?END_SOLUTION//gs;
$list = $list." ".$old.",".$filename."\n";
  }
  
  
  else
{ 
print $filename;
print "\n No solution found \n";

 }

write_file $filename, {binmode => ':utf8'}, $data;
}
#print "added the tracking code\n";
#Invoke with perl FormatV2.pl *.txt

print "\n";
$list =~ s/templates\//UNL-Problems\//g;

write_file "editsmade.txt", {binmode => ':utf8'}, $list;