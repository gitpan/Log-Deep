#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Deep' );
}

diag( "Testing Log::Deep $Log::Deep::VERSION, Perl $], $^X" );
