use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Giblog' ) || print "Bail out!\n";
    
    # Command compile tests
    use_ok( 'Giblog::Command::serve' ) || print "Bail out!\n";
    use_ok( 'Giblog::Command::publish' ) || print "Bail out!\n";
}

diag( "Testing Giblog $Giblog::VERSION, Perl $], $^X" );
