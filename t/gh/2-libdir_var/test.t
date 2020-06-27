#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

use Test::More;
use File::Basename;

my $testName = $FindBin::Bin;
my $distDir = dirname(dirname(dirname($FindBin::Bin)));

# print "distDir=$distDir\ntestName=$testName\n";

subtest q{use File::AddInc qw($libdir)}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "MyApp.pm";

  is qx($^X -I$distDir/lib $testDir/$targetFile), "FOObar\n", "\$libvar is set";

};

subtest q{use File::AddInc [libdir_var => qw($libdir)]}, sub {
  my $testDesc = "$testName/2.d";
  my $testDir = File::Spec->rel2abs($testDesc);
  my $targetFile = "MyApp.pm";

  is qx($^X -I$distDir/lib $testDir/MyApp.pm), "FOObar\n", "\$libvar is set";

};

done_testing();
