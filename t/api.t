use strict;
use warnings;
use utf8;

use lib 't/lib';

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

# run_command
{
  # run_command - run command
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $command = 'test';
    my $num = 0;
    $api->run_command($command, \$num);
    is($num, 3);
  }

  # run_command - exeption - can't find command
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $command = 'not_exists';
    eval {
      $api->run_command($command);
    };
    ok($@);
  }
}

# create_website_from_proto
{
  my $giblog_dir = 't/tmp/api/create_website';
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  
  # create_website_from_proto - path
  {
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($giblog_dir, $module_name);

    my @files = sort glob "$giblog_dir/*";

    is_deeply(
      \@files, 
      [
        "$giblog_dir/README",
        "$giblog_dir/giblog.conf",
        "$giblog_dir/lib",
        "$giblog_dir/public",
        "$giblog_dir/serve.pl",
        "$giblog_dir/templates",
      ]
    );
    
    my $readme_content = $api->slurp_file("$giblog_dir/README");
    like($readme_content, qr|Giblog/Command/new/proto|);
  }

  # create_website_from_proto - exception - module not loaded
  {
    my $module_name = 'Giblog::Command::not_found';
    eval {
      $api->create_website_from_proto($giblog_dir, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - home dir is not specified
  {
    unlink $giblog_dir;
    my $module_name = 'Giblog::Command::new';
    eval {
      $api->create_website_from_proto(undef, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - home dir is already exists
  {
    unlink $giblog_dir;
    mkdir $giblog_dir;
    my $module_name = 'Giblog::Command::new';
    eval {
      $api->create_website_from_proto($giblog_dir, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - module name is not specified
  {
    unlink $giblog_dir;
    eval {
      $api->create_website_from_proto($giblog_dir, undef);
    };
    ok($@);
  }

  # create_website_from_proto - exception - module is not loaded
  {
    unlink $giblog_dir;
    my $module_name = 'Giblog::Command::not_found';
    eval {
      $api->create_website_from_proto($giblog_dir, $module_name);
    };
    ok($@);
  }
}

# get_templates_files
{
  # get_templates_files - get template files
  {
    my $giblog_dir = 't/tmp/api/get_templates_files';
    my $giblog = Giblog->new(giblog_dir => $giblog_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($giblog_dir, $module_name);
    $api->create_file("$giblog_dir/templates/blog/1111.html");

    my $files = $api->get_templates_files;

    @$files = sort @$files;

    is_deeply(
      $files, 
      [
        "blog/1111.html",
        "index.html",
      ]
    );
  }

  # get_templates_files - get template files
  {
    my $giblog_dir = 't/tmp/api/get_templates_files';
    rmtree $giblog_dir;
    my $giblog = Giblog->new(giblog_dir => $giblog_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($giblog_dir, $module_name);

    my $files = $api->get_templates_files;
  }
}

# get_content
{
  # get_content - get content
  {
    my $giblog_dir = 't/tmp/api/get_content';
    rmtree $giblog_dir;
    my $giblog = Giblog->new(giblog_dir => $giblog_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($giblog_dir, $module_name);
    $api->write_to_file("$giblog_dir/templates/index.html", "あいう");
    
    my $data = {file => 'index.html'};
    $api->get_content($data);
    my $content = $data->{content};
    
    is($content, "あいう");
  }
}

# parse_giblog_syntax
{
  # parse_giblog_syntax - parse giblog syntax
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
Hello World!

<b>Hi, Yuki</b>

<div>
  OK
</div>

<pre>
my $foo = 1 > 3 && 2 < 5;
</pre>
EOS
    
    my $data = {content => $input};
    $api->parse_giblog_syntax($data);
    my $content = $data->{content};
    
    my $expect = <<'EOS';
<p>
  Hello World!
</p>
<p>
  <b>Hi, Yuki</b>
</p>
<div>
  OK
</div>
<pre>
my $foo = 1 &gt; 3 && 2 &lt; 5;
</pre>
EOS
    
    is($content, $expect);
  }
}

# parse_title
{
  # parse_title - parse title
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="title">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_title($data);
    my $title = $data->{title};
    
    is($title, "あいう");
  }
}
