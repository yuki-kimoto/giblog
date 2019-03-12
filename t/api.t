use strict;
use warnings;
use Test::More 'no_plan';

use Giblog::API;
use Giblog;

use File::Path 'mkpath', 'rmtree';

my $test_dir = 't/tmp/api';

rmtree $test_dir;
mkpath $test_dir;

# new
{
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  
  is(ref $api, 'Giblog::API');
  is($giblog, $api->giblog);
}

