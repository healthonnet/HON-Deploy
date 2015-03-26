use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HON::Deploy',
    license             => 'perl',
    dist_author         => q{Alexandre Masselot <alexandre.masselot@gmail.com>},
    dist_version_from   => 'lib/HON/Deploy.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'HON-Deploy-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
