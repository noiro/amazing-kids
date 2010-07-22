#!/usr/bin/perl
use IO::File;
#use utf8;

# this is a script to remove certain 
# items from dictionary definitions

my $INPUT_FILE="c:/temp/def.txt";
my $OUTPUT_FILE="c:/temp/def-clean.txt";

my $fh = new IO::File($INPUT_FILE);
defined $fh || die "cannot open file $INPUT_FILE: $!\n";

my $text = "";
while (<$fh>) {
  $text .= $_;
}

# remove things like \'n(y)?kle-?s\
$text =~ s/\\([^ ]*)\\//g;

#remove characters
$text =~ s/·//g;

# switched some of the non-common characters 
$text =~ s/‹/</g;
$text =~ s/›/>/g;
$text =~ s/—/-/g;

# except n, which will match n:
$text =~ s/ ([a-mo-z]) :/ ($1\)/g;

my $oh = new IO::File(">$OUTPUT_FILE"); 
defined $oh || die "cannot open output file $OUTPUT_FILE: $!\n";

$oh->print($text);

$oh->close();



 
