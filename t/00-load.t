#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Log::Deep'       );
	use_ok( 'Log::Deep::Read' );
}

diag( "Testing Log::Deep $Log::Deep::VERSION, Perl $], $^X" );
