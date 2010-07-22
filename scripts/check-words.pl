use Text::CSV;
use Text::CSV::Encoded;
use IO::File;

my $file = 'c://temp//Wordlist.csv';
my $file2 = 'c://temp//new.txt';

my $csv = Text::CSV::Encoded->new(
  { encoding_in => 'iso-8859-1'}
);

print "reading word list\n";

open (CSV, "<", $file) or die $!;
$count = 1;
while (<CSV>) {
  if ($csv->parse($_)) {
      next if ($count++ == 0);
      my @columns = $csv->fields();
      #print "@columns\n";
      $word = $columns[2];
      $word_idx= lc($word);
      #print "word=$word\n";
      $content{$word_idx} = $word;      
      #last if $count++ > 5;
      
      @words_arr = split(/\s+/, $word);
      foreach $w (@words_arr) {
        $w =~ s/[.,\"\-\?\:]//g;
        next if $word eq "";
        $words_idx{$w} = $word;
        #print "sav $w : $word\n";
      } 
  } else {
      my $err = $csv->error_input;
      print "Failed to parse line: $err";
  }
}
close CSV;
print "DB total: $count lines...\n";

my $fh = new IO::File($file2);
defined($fh) or die "cannot open file $file2: $!";

my $i = 0;
my $iNotFound=0;
while (<$fh>) {
  chomp $_;     
  @words_arr = split(/\s+/, $_);
  foreach $w (@words_arr) {    
    $found = check_word($w);
    if ($found =~ /RELATED/) {
        #print "$w => $found\n";
    } else {
      if ($found !~ /^FOUND/) {
        if (!$not_found{$w}) {
          # we don't want to repeat the printout for same word
          print ++$iNotFound, " NOT FOUND $w\n";          
          $not_found{$w} = $w;
        }        
      } else {
        if ($found =~ /like/) {
          print "  LIKE [$found]\n";
        }
        #print "FOUND [$w]\n";
      }
    }
  } 
  $i++;
  #last if $i++ > 5;
}
print "END checked $i lines\n";


#$sentence = join(" ",@ARGV);
#$found=check_word($sentence);
#if ($found eq "FOUND") {
#  print "sentence=[$sentence] FOUND!";
#} 

sub check_word {
  my $word = $_[0];
  my $w = $word;
  $w =~ s/[.,\"\-\?\:\(\)]//g;
  if ($w eq "") {
   return "FOUND";
  }
    
  my $ret;
  #print "check word=$word\n";
  if ($content{lc($w)}) {
    #print "check word=$word", "=>found\n";
    $ret="FOUND";
    return $ret;    
  } else {
    $ret="NOT FOUND";    
    #print "check word=$word", "=>NOT found\n";
  }
  
  # check for look alikes
  my $w2 = $w;
  my @alt = ();
  $w2 =~ s/s$//;
  push(@alt, $w2);
  
  $w2 = $w; $w2 =~ s/s$//; push(@alt, $w2);
  $w2 = $w; $w2 =~ s/ed$//; push(@alt, $w2);  
  $w2 = $w; $w2 =~ s/d$//; push(@alt, $w2); # cater to words like released

  foreach $w2 (@alt) {  
    if ($content{lc($w2)}) {
      $ret = "FOUND $word like $w2";
      #print "XXX", $ret, "\n";
      return $ret;
    }
  }    
  
  my $c = $words_idx{$w};
  if ($c && $c ne $w) {
    #print "$word related=$c\n";
    $ret = "RELATED to [$c]";
  }
  return $ret;
}
