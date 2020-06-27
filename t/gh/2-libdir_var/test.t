#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

use Test::More;
use File::Basename;

my $testName = $FindBin::Bin;
my $distDir = dirname(dirname(dirname($FindBin::Bin)));

# print "distDir=$distDir\ntestName=$testName\n";

subtest "1.d", sub {
  my $testDesc = "$testName/1.d";
  my $testDir = File::Spec->rel2abs($testDesc);
  my $targetFile = "MyApp.pm";

  is qx($^X -I$distDir/lib $testDir/MyApp.pm), "FOObar\n", "\$libvar is set";

};

done_testing();
