#!/usr/bin/perl
use File::Slurp qw(read_file write_file);
use File::Find::RULE;
use String::Unquotemeta;



my $filename = 'editsmade.txt';
my @dataname;
open(my $fh, '<', $filename) or die "Can't read file '$file' [$!]\n";
while (my $line = <$fh>) {
    chomp $line;
    my @fields = split(/,/, $line);
    push @dataname, \@fields;
}
my @files = File::Find::Rule->file->name("*.xml")->in(".");
foreach my $file (@files){

my $filename = $file;


#print $filename;
#print "\n";

my $data = read_file $file, {binmode => ':utf8'};
foreach my $csvline (@dataname){
$first=quotemeta(@$csvline[0]);
$second=quotemeta(@$csvline[1]);
if ($data =~ m/$first/){
print $filename;
print "\n";
#print "\n ".$second."\n";
$second = unquotemeta($second);
$data =~ s/$first/$second/gs;

write_file $filename, {binmode => ':utf8'}, $data;
}
}}
#print "added the tracking code\n";
#Invoke with perl FormatV2.pl *.txt
