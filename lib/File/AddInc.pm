package File::AddInc;
use 5.008001;
use strict;
use warnings;
use mro qw/c3/;

our $VERSION = "0.001";

use File::Spec;
use File::Basename;
use Cwd ();
use lib ();
use Carp ();

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

#
# Limited version of MOP4Import::Declare#import()
#
sub import {
  my ($pack, @pragma) = @_;

  my $opts = +{};

  $opts->{caller} = [caller];
  ($opts->{callpack}, $opts->{filename}, $opts->{line})
    = @{$opts->{caller}};

  @pragma = (-file_inc) unless @pragma;

  foreach my $pragmaSpec (@pragma) {

    my ($pragma, @args) = do {
      if (ref $pragmaSpec eq 'ARRAY') {
        @$pragmaSpec
      }
      elsif (not ref $pragmaSpec and $pragmaSpec =~ /^-(\w+)$/) {
        $1
      }
      elsif (not ref $pragmaSpec and $pragmaSpec =~ /^\$\w+\z/) {
        (libdir_var => $pragmaSpec)
      }
      else {
        Carp::croak "Unsupported pragma: $pragmaSpec";
      }
    };

    my $sub = $pack->can("declare_$pragma")
      or Carp::croak "Unknown pragma: $pragma";

    $sub->($pack, $opts, @args);
  }
}

sub declare_file_inc {
  my ($pack, $opts, $filename) = @_;

  # Limited emulation of m4i_args()
  my $callpack = ref $opts ? $opts->{callpack} : $opts;
  $filename //= $opts->{filename} if ref $opts;

  my $libdir = libdir($pack, $callpack, $filename);

  print STDERR "# use lib '$libdir'\n" if DEBUG;

  lib->import($libdir);
}

sub declare_local_lib {
  my ($pack, $opts, $filename) = @_;

  # Limited emulation of m4i_args()
  my $callpack = ref $opts ? $opts->{callpack} : $opts;
  $filename //= $opts->{filename} if ref $opts;

  my $libdir = libdir($pack, $callpack, $filename);

  my $local_lib = dirname($libdir)."/local/lib/perl5";

  print STDERR "# use lib '$libdir', '$local_lib'\n" if DEBUG;

  lib->import($libdir, $local_lib);
}

sub declare_libdir_var {
  my ($pack, $opts, $varname) = @_;

  my $callpack = ref $opts ? $opts->{callpack} : $opts;
  my $filename = $opts->{filename};

  my $libdir = libdir($pack, $callpack, $filename);

  $varname =~ s/^\$//;

  my $fullvarname = join("::", $callpack, $varname);

  my $glob = do {no strict qw/refs/; \*{$fullvarname}};

  print STDERR "# set \$$fullvarname = '$libdir'\n" if DEBUG;

  *$glob = \$libdir;
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
