use strict;
use warnings;
use utf8;
use Test::More 'no_plan';
use Encode 'decode', 'encode';

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

# giblog
{
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  is($giblog, $api->giblog);
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
    my $dir = 't/tmp/api/foo/create_dir';
    eval {
      $api->create_dir($dir);
    };
    ok($@);
  }
}

# create_file
{
  # create_file - create file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/create_file';
    $api->create_file($file);
    ok(-f $file);
  }

  # create_file - exception - Can't create file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/foo/create_file';
    eval {
      $api->create_file($file);
    };
    ok($@);
  }
}

# write_to_file
{
  # write_to_file - write content to file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/write_to_file';
    my $content = "あいう";
    $api->write_to_file($file, $content);
    ok(-f $file);
    open my $fh, '<', $file
      or die "Can't open $file: $!";
    my $content_from_file = do { local $/; <$fh> };
    $content_from_file = decode('UTF-8', $content_from_file);
    is($content_from_file, $content);
  }

  # write_to_file - exception - Can't create file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/foo/write_to_file';
    eval {
      $api->write_to_file($file);
    };
    ok($@);
  }
}

# slurp_file
{
  # slurp_file - slurp file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/slurp_file';
    my $content_input = "あいう";
    open my $fh, '>', $file
      or die "Can't open $file: $!";
    print $fh encode('UTF-8', $content_input);
    close $fh;
    
    my $content = $api->slurp_file($file);
    is($content, $content_input);
  }

  # slurp_file - exception - Can't create file
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $file = 't/tmp/api/foo/slurp_file';
    eval {
      $api->slurp_file($file);
    };
    ok($@);
  }
}

# rel_file
{
  # rel_file - create path
  {
    my $giblog_dir = 't/tmp/api';
    my $giblog = Giblog->new(giblog_dir => $giblog_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $rel_file = 'foo/bar';
    my $file = $api->rel_file($rel_file);
    is($file, "$giblog_dir/$rel_file");
  }

  # rel_file - no home dir
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $rel_file = 'foo/bar';
    my $file = $api->rel_file($rel_file);
    is($file, $rel_file);
  }
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
