#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use rlib "../lib";

#========================================

use Test::Kantan;
use File::Basename;
use File::Spec;

#
# This test reads t/20_import/*.d/testdesc and run specified tests.
#
# Each testdesc must have following format, line-by-line:
#
#   Target Module Filename (relative to testdesc directory)
#   Expected (trailing) output...
#
# Each target module should emit result of File::AddInc->libdir and
# rest of expected outputs.

describe "use File::AddInc", sub {

  (my $testName = $0) =~ s/\.t\z//;

  foreach my $testDesc (<$testName/*.d/testdesc>) {

    my $testDir = File::Spec->rel2abs(dirname($testDesc));

    # First line is test target module (which must be runnable)
    # Rest of lines are expected output.
    my ($targetFile, @expect) = read_file_lines($testDesc);

    describe "case $testDesc", sub {

      my $exe = File::Spec->catfile($testDir, $targetFile);

      expect([qx($^X -I$FindBin::Bin/../lib $exe)])
        ->to_be([map {"$_\n"} $testDir, @expect]);
    };
  }

};

done_testing();

sub read_file_lines {
  my ($fn) = @_;
  open my $fh, '<', $fn or Carp::croak "Can't open $fn: $!";
  chomp(my @lines = <$fh>);
  wantarray ? @lines : \@lines;
}
