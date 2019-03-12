use strict;
use warnings;
use Test::More 'no_plan';

use Giblog::API;
use Giblog;

# new
{
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  
  is(ref $api, 'Giblog::API');
  is($giblog, $api->giblog);
}

