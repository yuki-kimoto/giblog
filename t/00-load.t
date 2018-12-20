#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Giblog' ) || print "Bail out!\n";
}

diag( "Testing Giblog $Giblog::VERSION, Perl $], $^X" );
