#!perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

require Test::NoWarnings;
Test::NoWarnings->import();

my @files = all_pod_files();
plan tests => @files + 1;

for my $file (@files) {
	pod_file_ok($file, "$file POD OK");
}
