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

# giblog_dir
{
  # giblog_dir - get Giblog directory
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    is($api->giblog_dir, 't/tmp/api');
  }
}

# read_config
{
  # read_config - read config
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '{foo => 1}';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    my $config = $api->read_config;
    is_deeply($config, {foo => 1});
  }
  
  # read_config - exception - syntax error
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = 'use strict; PPPPP;';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    eval {
      my $config = $api->read_config;
    };
    ok($@);
  }

  # read_config - exception - not hash reference
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '[]';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    eval {
      my $config = $api->read_config;
    };
    ok($@);
  }
}

# clear_config
{
  # clear_config - clear config
  {
    my $giblog = Giblog->new(giblog_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '{foo => 1}';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    my $config = $api->read_config;
    is_deeply($config, {foo => 1});
    $api->clear_config;
    ok(! defined $api->config);
  }
}

# create_dir
{
  # create_dir - create directory
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $dir = 't/tmp/api/create_dir';
    $api->create_dir($dir);
    ok(-d $dir);
  }

  # create_dir - exception - Can't create directory
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $dir = 't/tmp/api/foo/bar';
    eval {
      $api->create_dir($dir);
    };
    ok($@);
  }
}

# create_file
{
  # create_file - create fileectory
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/create_file';
    $api->create_file($file);
    ok(-f $file);
  }

  # create_file - exception - Can't create fileectory
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/foo/bar';
    eval {
      $api->create_file($file);
    };
    ok($@);
  }
}
