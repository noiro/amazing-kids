#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use XML::XPath;
use Data::Dumper;

#use constant NOMRAL_DISPLAY => "_";
use constant NOMRAL_DISPLAY => "";
#use constant UNDERLINE => "\e[0;4m";
use constant UNDERLINE => "";
#use constant UNDERLINE => "_";
use constant HOSTNAME => "http://services.aonaware.com";
#use constant DICTIONARY => "gcide";
use constant DICTIONARY => "wn";
use constant STRATEGY => "lev";
use constant DEFINE_URL => 
	HOSTNAME . "/DictService/DictService.asmx/DefineInDict?dictId=" . DICTIONARY . "&word=";
use constant SEARCH_URL_1 => HOSTNAME ."/DictService/DictService.asmx/MatchInDict?dictId=" . DICTIONARY . "&word=";
use constant SEARCH_URL_2 => "&strategy=" . STRATEGY;

# if ($#ARGV == -1) {
# 	print STDERR "No command line args specified\n";
# 	exit 1;
# }

my $IN_FILE = "c:/temp/words.txt";
my $OUT_FILE = "c:/temp/def.txt";

use IO::File;

my $fh = new IO::File($IN_FILE);
defined ($fh) || die "cannot open $IN_FILE: error=$!";

my $oh = new IO::File(">$OUT_FILE");
defined ($oh) || die "cannot write to $OUT_FILE: error=$!";

my $count = 0;

while (<$fh>) {
  my $w = $_;
  chomp $w;
  
  print "[$count] checking $w\n"; $count++;
  # == is a delimiter for word macros to pick up formatting
  $oh->print("==");
  $oh->print(get_def($w));
  sleep(0.5);
}
$oh->close();
$fh->close();

sub get_def {
  my $word = shift;
  $word =~ s/\s+//g;
  if (!$word) {
    return;
  }
	my $rawXml = get(DEFINE_URL . $word);
	#print DEFINE_URL . $word . "\n";
	
  my $xp = XML::XPath->new(xml => $rawXml);
	my $data = $xp->find('//Definition/WordDefinition');
	if ($data->size == 0) {
  	print "No Matches for $word\n";
  	return "$word : no match";
    $rawXml = get(SEARCH_URL_1 . $word . SEARCH_URL_2);
		$xp = XML::XPath->new(xml => $rawXml);
		$data = $xp->find('//DictionaryWord/Word');
		if ($data->size > 0) {
			print "Did you mean: -\n";
			for my $def ($data->get_nodelist) {
				return subst_string($def->string_value) . "\n";
			}
		}
	} else {   
		my $count = 1;
		for my $def ($data->get_nodelist) { 
  		#print UNDERLINE . $word . " DEFINITION $count" . NOMRAL_DISPLAY . "\n";
  		return subst_string($def->string_value) . "\n";
  		$count++;
		}
	}
}

sub subst_string {
  my $def = shift;
  $def =~ s/\n//g;
  $def =~ s/\r//g;
  $def =~ s/ +/ /g;
  $def =~ s/\s+(n|adj|adv|v) /\n$1\n/;  
  # we look for numbers followed by colon as line delimiters
  $def =~ s/\s+([\d+])\:/\n$1 \:/g;
  # trim duplicate spaces  
  #$def =~ s/\[syn: ([^]]*)]/$1/g;
  # get rid of anonymns
  #$def =~ s/\[ant: ([^]]*)]//g;
  #$def =~ s/\{([^}]*)}/\*$1/g;
  return "$def";  
}