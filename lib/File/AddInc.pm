package File::AddInc;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use File::Spec;
use File::Basename;
use Cwd ();
use lib ();
use Carp ();

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub import {
  my ($pack) = @_;

  my ($callpack, $filename, $line) = caller;

  $pack->declare_file_inc($callpack, $filename);
}

sub declare_file_inc {
  my ($pack, $callpack, $filename) = @_;

  my $libdir = libdir($pack, $callpack, $filename);

  print STDERR "# use lib '$libdir'\n" if DEBUG;

  lib->import($libdir);
}

sub libdir {
  my ($pack, @caller) = @_;

  my ($callpack, $filename) = @caller ? @caller : caller;

  (my $packfn = $callpack) =~ s,::,/,g;
  $packfn .= ".pm";

  my $realFn = -l $filename
    ? resolve_symlink($pack, $filename)
    : $filename;

  my $absfn = File::Spec->rel2abs($realFn);

  $absfn =~ /\Q$packfn\E\z/
    or Carp::croak("Can't handle this case! absfn=$absfn; packfn=$packfn");

  substr($absfn, 0, length($absfn) - length($packfn) - 1);
}

sub resolve_symlink {
  my ($pack, $filePath) = @_;

  print STDERR "# resolve_symlink($filePath)...\n" if DEBUG;

  (undef, my ($realDir)) = fileparse($filePath);

  while (defined (my $linkText = readlink $filePath)) {
    ($filePath, $realDir) = resolve_symlink_1($pack, $linkText, $realDir);
    print STDERR "# => $filePath (realDir=$realDir)\n" if DEBUG;
  }

  return $filePath;
}

sub resolve_symlink_1 {
  my ($pack, $linkText, $realDir) = @_;

  my $filePath = do {
    if (File::Spec->file_name_is_absolute($linkText)) {
      $linkText;
    } else {
      File::Spec->catfile($realDir, $linkText);
    }
  };

  if (wantarray) {
    # purify x/../y to y
    my $realPath = Cwd::realpath($filePath);
    (undef, $realDir) = fileparse($realPath);
    ($realPath, $realDir);
  } else {
    $filePath;
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

File::AddInc - FindBin(+ use lib) alike for *.pm (instead of *.pl)

=head1 SYNOPSIS

Suppose you have a module (say F<MyApp/Deep/Runnable/Module.pm>)
and want to make it runnable with shbang (C<#!perl>), C<chmod a+x>
and symlink it from your F<~/bin> (Yes, I'm sane;-).
In the module, you want to use some other module (F<MyApp/Util.pm>)
in the same library tree.
File::AddInc will locate your lib directory and modify @INC for you.


    #!/usr/bin/env perl
    package MyApp::Deep::Runnable::Module;

    # use MyApp::Util; # This may fail because @INC can be wrong in many ways.

    # So, use this to modify @INC.
    use File::AddInc;

    # Then perl can find MyApp/Util.pm correctly.
    use MyApp::Util;

    ...

=head1 DESCRIPTION

File::AddInc does similar task of L<FindBin> + L<lib>, but for Modules (F<*.pm>)
instead of standalone scripts (F<*.pl>).

Conceptually, this module locates root of F<lib> directory
through following steps.

=over 4

=item 1.

Inspect C<__FILE__> (using L<caller()|perlfunc/caller>).

=item 2.

Resolve symbolic links.

=item 3.

Trim C<__PACKAGE__> part from it.

=back

Then adds it to C<@INC>.


=head1 CLASS METHODS

=head2 C<libdir($PACKNAME, $FILEPATH)>
X<libdir>

Trims C<$PACKNAME> portion from C<$FILEPATH>.
When arguments are omitted, results from L<caller()|perlfunc/caller> is used.

  my $libdir = File::AddInc->libdir('MyApp::Foobar', "/somewhere/lib/MyApp/Foobar.pm");
  # $libdir == "/somewhere/lib"

  my $libdir = File::AddInc->libdir(caller);

  my $libdir = File::AddInc->libdir;


=head2 Note for MOP4Import users

This module does *NOT* rely on L<MOP4Import::Declare>
but designed to co-operate well with it. Actually,
this module provides C<declare_file_inc> method.
So, you can inherit 'File::AddInc'.

  package MyExporter;
  use MOP4Import::Declare -as_base, [base => 'File::AddInc'];

And then you can use C<-file_inc> pragma like following:

  use MyExporter -file_inc;

=head1 CAVEATS

Since this module compares C<__FILE__> with C<__PACKAGE__> in case
sensitive manner, it may not work well with modules which relies case
insensitive filesystems.

=head1 SEE ALSO

L<FindBin>, L<lib>, L<rlib>, L<blib>

=head1 LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kobayasi, Hiroaki E<lt>buribullet@gmail.comE<gt>

=cut
