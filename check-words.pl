#use Text::CSV;
#use Text::CSV::Encoded;
use IO::File;

# you will need to install this package and all the dependencies
# on windows using ActivePerl, run 'ppm' to install new packages
# from CPAN
use Spreadsheet::Read;
use Data::Dumper;

## TODO:
## script generates lots of warnings like the following, which is ignoring
## Use of uninitialized value in join or string at C:/Perl/site/lib/Spreadsheet/ReadSXC.pm line 198.
## they appears to be benign though

######## Constants which you should change as needed ######

# data file name, we assumpt ods files
my $DATA_FILENAME = "Wordlist20100623.ods";

# The target sheet in the spreadsheet where you store the 
# words 
my $TARGET_SHEET = "Word List";

# The columns in spreadsheet to read, note that first column is 
# column 1 not column zero
my $TARGET_COL = 3;

# this should be a plain text file used to check for new 
# words. it would be easier if you just cut-and-paste
# to replace the contents each time prior to running
# the perl program
my $INPUT_FILENAME = 'c://temp//new.txt' ;

############################################################

print "Reading DB\n";

# read data in, surpress populating of individual named cells
my $ref = ReadData($DATA_FILENAME, cells => false);

# sample read format
# $ref = [
#         # Entry 0 is the overall control hash
#         { sheets  => 2,
#           sheet   => {
#             "Sheet 1"   => 1,
#             "Sheet 2"   => 2,
#             },
#           type    => "xls",
#           parser  => "Spreadsheet::ParseExcel",
#           version => 0.26,
#           },
#         # Entry 1 is the first sheet
#         { label  => "Sheet 1",
#           maxrow => 2,
#           maxcol => 4,
#           cell   => [ undef,
#             [ undef, 1 ],
#             [ undef, undef, undef, undef, undef, "Nugget" ],
#             ],
#           A1     => 1,
#           B5     => "Nugget",
#           },
#         # Entry 2 is the second sheet
#         { label => "Sheet 2",
#           :
#         :

print "Number of words read: ", read_word_count($ref), "\n";

for ($i=1; $i < read_word_count($ref); $i++) {
  $word = read_word_idx($ref, $i);
  
  $word_idx=lc($word);
  #print "word=$word\n";
  
  # store orginal content
  $content{$word_idx} = $word;      
  #last if $count++ > 5;
  
  # rudimentary parsing
  # we need to account for the input 'word' being
  # actually a phrase or sentence, in which case
  # we store the component words 

  @words_arr = split(/\s+/, $word);
  foreach $w (@words_arr) {
    # get rid of common punctuactions
    $w =~ s/[.,\"\-\?\:]//g;
    next if $word eq "";
    $words_idx{$w} = $word;
    #print "sav $w : $word\n";
  } 
      
  #print "[$i]\t", $word, "\n";
  #last if ($i ==10);
}  

print "DB total: $i lines...\n";

my $fh = new IO::File($INPUT_FILENAME);
defined($fh) or die "cannot open file $INPUT_FILENAME: $!";

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
  # note that the assumption here is that we have the root word in the
  # database
  my @subs = (
  [qr/ed$/i, ""],  # words like played   
  [qr/ed$/i, "e"],  # words like released
  [qr/s$/i, ""],   # words like plays  
  [qr/ies$/i, "y"],    # words like flies
  [qr/ing$/i, ""],    # words like playing  
  );

  foreach $r (@subs) {
    #print $r->[0], "===>", $r->[1], "\n";
    $w2 = $w;
    $w2 =~ s/$r->[0]/$r->[1]/i;
    # check against the variant
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

# define some helper apps to abstract the references to the sheets  
sub read_word_count() {
  my $ref = shift;
  my $sheet_num = $ref->[0]{sheet}{$TARGET_SHEET};
  return $ref->[$sheet_num]{maxrow}; 
}         

sub read_word_idx() {
  my($ref,$idx) = @_;
  my $sheet_num = $ref->[0]{sheet}{$TARGET_SHEET};
  #$cell = cr2cell(2,$ix);
  #print "getting cell $cell\n";
  return $ref->[$sheet_num]{cell}[$TARGET_COL][$idx];
}
