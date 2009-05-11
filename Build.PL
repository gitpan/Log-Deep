use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Log::Deep',
	license             => 'perl',
	dist_author         => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from   => 'lib/Log/Deep.pm',
	build_requires => {
		'Test::More'           => 0,
		'Data::Dump::Streamer' => '2.08',
		'Readonly'             => '1.03',
		'Time::HiRes'          => '1.9711',
		'Clone'                => '0.29',
	},
	add_to_cleanup      => [ 'Log-Deep-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
