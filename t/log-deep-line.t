#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13 + 1;
use Test::NoWarnings;
use Data::Dump::Streamer;

use File::Touch;
use File::Slurp qw/slurp/;
use Log::Deep::Line;
use Log::Deep::File;

File::Touch->new->touch('test');
my $file = Log::Deep::File->new( name => 'test' );
my $dds  = Data::Dump::Streamer->new()->Indent(4);
my $deep = Log::Deep::Line->new(dump => $dds);
isa_ok( $deep, 'Log::Deep::Line', 'Can create a log object');

# TESTING the parse line method
$deep->parse( 'date,session,level,message,$DATA={};', $file );
is( $deep->{date}       , 'date', 'The data structure is as expected' );
is( $deep->{session}    , 'session', 'The data structure is as expected' );
is( $deep->{level}      , 'level', 'The data structure is as expected' );
is( $deep->{message}    , 'message', 'The data structure is as expected' );
is_deeply( $deep->{DATA}, {}, 'The data structure is as expected' );

$deep->parse( 'date,session,level,message \, test\n,$DATA={};', $file );
is( $deep->{date}       , 'date', 'The data structure is as expected' );
is( $deep->{session}    , 'session', 'The data structure is as expected' );
is( $deep->{level}      , 'level', 'The data structure is as expected' );
is( $deep->{message}    , "message , test\n", 'The data structure is as expected' );
is_deeply( $deep->{DATA}, {}, 'The data structure is as expected' );

# Testing show_line method
$deep->parse( 'date,session,level,message \, test\n,$DATA={};', $file );
ok( $deep->show(), 'Ordinarly the line is displayed');
$deep->parse( ',session,level,message \, test\n,$DATA={};', $file );
ok( !$deep->show(), 'no data the line is not displayed');

unlink 'test';
