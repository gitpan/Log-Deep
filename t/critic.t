
use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
require Perl::Critic::Utils;
Perl::Critic::Utils->import(qw/all_perl_files/);

require Test::NoWarnings;
Test::NoWarnings->import();

my @files = all_perl_files('bin', -d 'blib' ? 'blib' : 'lib' );
plan tests => @files + 1;

for my $file (@files) {
	critic_ok($file, "$file POD OK");
}
