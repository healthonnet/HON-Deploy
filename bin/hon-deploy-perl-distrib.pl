#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use LWP::Simple qw/mirror/;
use IO::All;
use Archive::Tar;
use Module::Build;
use File::Temp qw/tempdir/;

=head1 NAME

hon-deploy-mirror.pl 

=head1 DESCRIPTION

deploy the mirror perl module + bin + cgi

=head1 SYNOPSIS

 ./hon-deploy-perl-distrib.pl --dist=path/to/HON-Http-Mirror.tar.gz --dir-bin=/path/to/bin --dir-lib=/path/to/lib --dir-cgi=/path/to/cgi
 
 ./hon-deploy-perl-distrib.pl --dist=http://znverdi.hcuge.ch/~hondev/perl/dist/HON-Http-Mirror-latest.tar.gz --dir-bin=/tmp/mirror-dist/bin --dir-lib=/tmp/mirror-dist/lib
 
 ./hon-deploy-perl-distrib.pl  --dist=http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Utils-latest.tar.gz,http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Http-Mirror-latest.tar.gz   --dir-base=$HOME/perl --dir-cgi=$HOME/public_html/cgi-bin --perl-interpreter=$(which perl) 
 
=head1 ARGUMENTS

=over 2

=item --dist=/path/to/HON-Http-Mirror-x.yy.tar.gz

Either file or url

=item --dir-base=/path/to/base 

Where the default per is to be deployed are to be installed


=back

=head1 OPTIONS

=over 2

=item --dir-cgi=/path/to/cgi

Where the CGI scripts are to be installed

=back

=cut

my ($help);
my ( $pDistSrc, $pDirBase, $pDirCgi, $perlInterpeter );

GetOptions(
  "dist=s"             => \$pDistSrc,
  "dir-base=s"         => \$pDirBase,
  "dir-cgi=s"          => \$pDirCgi,
  "perl-interpreter=s" => \$perlInterpeter,
  "help"               => \$help,
  )
  || pod2usage(2);

if ( $help || !$pDirBase || !$pDistSrc ) {
  pod2usage(1);
  exit(0);
}

foreach my $dSrc ( split( /,/, $pDistSrc ) ) {
  installDistrib( src => $dSrc, base => $pDirBase, cgi => $pDirCgi );
}

sub installDistrib {
  my %args    = @_;
  my $distSrc = $args{src};
  my $dirBase = $args{base};
  my $dirCgi  = $args{cgi};

  my $tmpdir = tempdir(TEMPLATE=>'hon-deploy-XXXXXXXX', CLEANUP => 1 );

  my $distGz = "$tmpdir/dist.tgz";
  warn "mirroring: $distSrc\n";
  if ( $distSrc =~ /^(https?|ftp):\/\// ) {
    mirror( $distSrc, $distGz );
  }
  else {
    io($distSrc) > io($distGz);
  }
  my $tar = Archive::Tar->new;

  $tar->read($distGz);
  $tar->setcwd($tmpdir);
  $tar->extract();
  my $distTmpir = "$tmpdir/" . ( split( /\//, ( $tar->list_files() )[0] ) )[0];
  warn "working dir: $distTmpir\n";
  chdir($distTmpir);

  if($perlInterpeter){
    my @scripts;
    @scripts= grep {"$_" =~/\.pl$/i} io('bin')->all() if -d 'bin';
    
    push @scripts,  grep {"$_" =~/\.(pl|cgi)$/i} io('cgi')->all() if -d "cgi";
    foreach my $s (@scripts){
      system "chmod +w $s"; 
      my $txt = io($s)->slurp;
      $txt=~s/^#!.*?\n/#!$perlInterpeter\n/s;
      io($s)<$txt;
      system "chmod -w $s"; 
    }
  }

  my @cmd = ( 'perl Build.PL', './Build test', "./Build install  --install_base $dirBase" );
  $cmd[2] .= " --install_path cgi=$dirCgi" if $dirCgi;

  foreach my $cmd (@cmd) {
    warn "$cmd\n";
    system($cmd) && die "cannot execute";
  }
  chdir( $ENV{HOME} );
}
