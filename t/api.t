use strict;
use warnings;
use Test::More 'no_plan';

use Giblog::API;
use Giblog;
use Giblog::Command::new;

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

# get_proto_dir
{
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  
  # get_proto_dir - path
  {
    my $module_name = 'Giblog::Command::new';
    my $proto_dir = $api->get_proto_dir($module_name);
    like($proto_dir, qr|blib/lib/Giblog/Command/new/proto$|);
    ok(-d $proto_dir);
  }
  
  # get_proto_dir - exception - module not found
  {
    my $module_name = 'Giblog::Command::not_found';
    eval {
      my $proto_dir = $api->get_proto_dir($module_name);
    };
    ok($@);
  }
}

# config
{
  # config - default is undef
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    ok(!defined $api->config);
  }
  
  # config - read config
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '{foo => 1}';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    $api->read_config;
    my $config = $api->config;
    is_deeply($config, {foo => 1});
  }
}
