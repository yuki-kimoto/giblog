use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Giblog' ) || print "Bail out!\n";
    
    # Command compile tests
    use_ok( 'Giblog::Command::save' ) || print "Bail out!\n";
    use_ok( 'Giblog::Command::serve' ) || print "Bail out!\n";
    use_ok( 'Giblog::Command::publish' ) || print "Bail out!\n";
    use_ok( 'Giblog::Command::all' ) || print "Bail out!\n";
}

diag( "Testing Giblog $Giblog::VERSION, Perl $], $^X" );
