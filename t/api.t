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
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '{foo => 1}';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    $api->read_config;
    my $config = $api->config;
    is_deeply($config, {foo => 1});
  }
}

# home_dir
{
  # home_dir - get Giblog directory
  {
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    is($api->home_dir, 't/tmp/api');
  }
}

# read_config
{
  # read_config - read config
  {
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
    my $api = Giblog::API->new(giblog => $giblog);
    my $config_content = '{foo => 1}';
    $api->write_to_file('t/tmp/api/giblog.conf', $config_content);
    my $config = $api->read_config;
    is_deeply($config, {foo => 1});
  }
  
  # read_config - exception - syntax error
  {
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
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
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
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
    my $giblog = Giblog->new(home_dir => 't/tmp/api');
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
    my $home_dir = 't/tmp/api';
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $rel_file = 'foo/bar';
    my $file = $api->rel_file($rel_file);
    is($file, "$home_dir/$rel_file");
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

# create_website_from_proto
{
  my $home_dir = 't/tmp/api/create_website';
  my $giblog = Giblog->new;
  my $api = Giblog::API->new(giblog => $giblog);
  
  # create_website_from_proto - path
  {
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);

    my @files = sort glob "$home_dir/*";

    is_deeply(
      \@files, 
      [
        "$home_dir/README",
        "$home_dir/deploy.pl",
        "$home_dir/giblog.conf",
        "$home_dir/lib",
        "$home_dir/public",
        "$home_dir/serve.pl",
        "$home_dir/templates",
      ]
    );
    
    my $readme_content = $api->slurp_file("$home_dir/README");
    like($readme_content, qr|Title|);
  }

  # create_website_from_proto - exception - module not loaded
  {
    my $module_name = 'Giblog::Command::not_found';
    eval {
      $api->create_website_from_proto($home_dir, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - home dir is not specified
  {
    unlink $home_dir;
    my $module_name = 'Giblog::Command::new';
    eval {
      $api->create_website_from_proto(undef, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - home dir is already exists
  {
    unlink $home_dir;
    mkdir $home_dir;
    my $module_name = 'Giblog::Command::new';
    eval {
      $api->create_website_from_proto($home_dir, $module_name);
    };
    ok($@);
  }

  # create_website_from_proto - exception - module name is not specified
  {
    unlink $home_dir;
    eval {
      $api->create_website_from_proto($home_dir, undef);
    };
    ok($@);
  }

  # create_website_from_proto - exception - module is not loaded
  {
    unlink $home_dir;
    my $module_name = 'Giblog::Command::not_found';
    eval {
      $api->create_website_from_proto($home_dir, $module_name);
    };
    ok($@);
  }
}

# copy_static_files_to_public
{
  # copy_static_files_to_public - copy static files to public directory
  {
    my $home_dir = 't/tmp/api/copy_static_files_to_public';
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    
    # Binary
    {
      my $binary = pack "l4", 1, 2, 3, 4;
      my $file = "$home_dir/templates/static/foo.png";
      open my $out_fh, '>', $file
        or die "Can't file $file : $!";
      binmode $out_fh;
      print $out_fh $binary;
    }

    my $files = $api->copy_static_files_to_public;
    
    ok(-f "$home_dir/public/js/.gitkeep");
    ok(-f "$home_dir/public/images/.gitkeep");
    ok(-f "$home_dir/public/css/common.css");
    ok(-f "$home_dir/public/blog/.gitkeep");
    ok(-f "$home_dir/public/foo.png");
    
    {
      my $file = "$home_dir/templates/static/foo.png";
      open my $in_fh, '<', $file
        or die "Can't file $file : $!";
      local $/;
      my $binary = <$in_fh>;
      my $binary_expected = pack "l4", 1, 2, 3, 4;
      
      is($binary, $binary_expected);
    }
  }
}

# get_templates_files
{
  # get_templates_files - get template files
  {
    my $home_dir = 't/tmp/api/get_templates_files';
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    $api->create_file("$home_dir/templates/blog/1111.html");

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
    my $home_dir = 't/tmp/api/get_templates_files';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);

    my $files = $api->get_templates_files;
  }
}

# get_content
{
  # get_content - get content
  {
    my $home_dir = 't/tmp/api/get_content';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    $api->write_to_file("$home_dir/templates/index.html", "あいう");
    
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
my $foo = 1 > 3 && 1 > 3 && 2 < 5 && 2 < 5;
</pre>
<script>
  alert('aaa');
</script>
<style>
  body {}
</style>
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
my $foo = 1 &gt; 3 &amp;&amp; 1 &gt; 3 &amp;&amp; 2 &lt; 5 &amp;&amp; 2 &lt; 5;
</pre>
<script>
  alert('aaa');
</script>
<style>
  body {}
</style>
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

  # parse_title - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="not_found">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_title($data);
    my $title = $data->{title};
    
    ok(!defined $title);
  }
}

# parse_title_from_first_h_tag
{
  # parse_title_from_first_h_tag - parse title from first h1 tag
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<h1>あいう</h1>
EOS
    
    my $data = {content => $input};
    $api->parse_title_from_first_h_tag($data);
    my $title = $data->{title};
    
    is($title, "あいう");
  }

  # parse_title_from_first_h_tag - parse title from first h6 tag
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<h6>あいう</h6>
EOS
    
    my $data = {content => $input};
    $api->parse_title_from_first_h_tag($data);
    my $title = $data->{title};
    
    is($title, "あいう");
  }

  # parse_title_from_first_h_tag - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<h7">あいう</h7>
EOS
    
    my $data = {content => $input};
    $api->parse_title_from_first_h_tag($data);
    my $title = $data->{title};
    
    ok(!defined $title);
  }
}

# add_page_link
{
  # add_page_link - add page link - entry page
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'blog/20181012123456.html';
    $data->{content} = '<div class="title">Perl Tutorial</div>';
    $api->add_page_link($data);
    my $content = $data->{content};
    is($content, '<div class="title"><a href="/blog/20181012123456.html">Perl Tutorial</a></div>');
  }

  # add_page_link - add page link - root
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'index.html';
    $data->{content} = '<div class="title">Perl Tutorial</div>';
    $api->add_page_link($data, {root => 'index.html'});
    my $content = $data->{content};
    is($content, '<div class="title"><a href="/">Perl Tutorial</a></div>');
  }

  # add_page_link - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'blog/20181012123456.html';
    $data->{content} = '<div class="not_found">Perl Tutorial</div>';
    $api->add_page_link($data, {root => 'index.html'});
    my $content = $data->{content};
    is($content, '<div class="not_found">Perl Tutorial</div>');
  }
}

# add_page_link_to_first_h_tag
{
  # add_page_link_to_first_h_tag - add page link - entry page
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'blog/20181012123456.html';
    $data->{content} = '<h1>Perl Tutorial</h1>';
    $api->add_page_link_to_first_h_tag($data);
    my $content = $data->{content};
    is($content, '<h1><a href="/blog/20181012123456.html">Perl Tutorial</a></h1>');
  }

  # add_page_link_to_first_h_tag - add page link - top page
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'index.html';
    $data->{content} = '<h1>Perl Tutorial</h1>';
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});
    my $content = $data->{content};
    is($content, '<h1><a href="/">Perl Tutorial</a></h1>');
  }

  # add_page_link_to_first_h_tag - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{file} = 'blog/20181012123456.html';
    $data->{content} = '<h7>Perl Tutorial</h7>';
    $api->add_page_link_to_first_h_tag($data);
    my $content = $data->{content};
    is($content, '<h7>Perl Tutorial</h7>');
  }
}

# add_content_after_first_h_tag
{
  # add_content_after_first_h_tag - h1
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h1>Perl Tutorial</h1>\n<h2>Foo</h2>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h1>Perl Tutorial</h1>\n<div>Added contents</div>\n<h2>Foo</h2>\n");
  }

  # add_content_after_first_h_tag - h2
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h2>Perl Tutorial</h2>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h2>Perl Tutorial</h2>\n<div>Added contents</div>\n");
  }

  # add_content_after_first_h_tag - h3
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h3>Perl Tutorial</h3>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h3>Perl Tutorial</h3>\n<div>Added contents</div>\n");
  }

  # add_content_after_first_h_tag - h4
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h4>Perl Tutorial</h4>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h4>Perl Tutorial</h4>\n<div>Added contents</div>\n");
  }

  # add_content_after_first_h_tag - h5
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h5>Perl Tutorial</h5>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h5>Perl Tutorial</h5>\n<div>Added contents</div>\n");
  }

  # add_content_after_first_h_tag - h6
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h6>Perl Tutorial</h6>\n";
    $api->add_content_after_first_h_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h6>Perl Tutorial</h6>\n<div>Added contents</div>\n");
  }
}

# add_content_after_first_p_tag
{
  # add_content_after_first_p_tag - h1
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = "<h2>Perl Tutorial</h2>\n<p>Foo</p>\n<p>Bar</p>\n";
    $api->add_content_after_first_p_tag($data, {content => '<div>Added contents</div>'});
    my $content = $data->{content};
    is($content, "<h2>Perl Tutorial</h2>\n<p>Foo</p>\n<div>Added contents</div>\n<p>Bar</p>\n");
  }
}

# parse_description
{
  # parse_description - parse description
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="description">
  あいう
</div>
EOS
    
    my $data = {content => $input};
    $api->parse_description($data);
    my $description = $data->{description};
    
    is($description, "あいう");
  }

  # parse_description - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="not_found">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_description($data);
    my $description = $data->{description};
    
    ok(!defined $description);
  }
}

# parse_description_from_first_p_tag
{
  # parse_description_from_first_p_tag - parse description from first p tag
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<p>
  Perl Tutorial is site for beginners of Perl 
</p>
<p>
  Foo, Bar
</p>
EOS
    
    my $data = {content => $input};
    $api->parse_description_from_first_p_tag($data);
    my $description = $data->{description};
    
    is($description, "Perl Tutorial is site for beginners of Perl");
  }

  # parse_description_from_first_p_tag - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="not_found">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_description_from_first_p_tag($data);
    my $description = $data->{description};
    
    ok(!defined $description);
  }

  # parse_description_from_first_p_tag - contains tag and new line new line
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<"EOS";
<p>
  Perl Tutorial2 is <a href="">site</a> for <b>beginners\n</b> of Perl 
</p>
<p>
  Foo, Bar
</p>
EOS
    
    my $data = {content => $input};
    $api->parse_description_from_first_p_tag($data);
    my $description = $data->{description};
    
    is($description, "Perl Tutorial2 is site for beginners of Perl");
  }

}

# parse_keywords
{
  # parse_keywords - parse keywords
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="keywords">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_keywords($data);
    my $keywords = $data->{keywords};
    
    is($keywords, "あいう");
  }

  # parse_keywords - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="not_found">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_keywords($data);
    my $keywords = $data->{keywords};
    
    ok(!defined $keywords);
  }
}

# parse_first_img_src
{
  # parse_first_img_src - parse img src
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<img class="ppp" src="/path">
<img class="ppp" src="/path2">
EOS
    
    my $data = {content => $input};
    $api->parse_first_img_src($data);
    my $img_src = $data->{img_src};
    
    is($img_src, "/path");
  }

  # parse_first_img_src - not found
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $input = <<'EOS';
<div class="not_found">あいう</div>
EOS
    
    my $data = {content => $input};
    $api->parse_first_img_src($data);
    my $img_src = $data->{img_src};
    
    ok(!defined $img_src);
  }
}

# read_common_templates
{
  # read_common_templates - read common templates in "templates/common" directory.
  {
    my $home_dir = 't/tmp/api/read_common_templates';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    
    $api->write_to_file("$home_dir/templates/common/meta.html", "あ");
    $api->write_to_file("$home_dir/templates/common/header.html", "い");
    $api->write_to_file("$home_dir/templates/common/footer.html", "う");
    $api->write_to_file("$home_dir/templates/common/side.html", "え");
    $api->write_to_file("$home_dir/templates/common/top.html", "お");
    $api->write_to_file("$home_dir/templates/common/bottom.html", "か");

    my $data = {};
    $api->read_common_templates($data);
    
    is($data->{meta}, "あ");
    is($data->{header}, "い");
    is($data->{footer}, "う");
    is($data->{side}, "え");
    is($data->{top}, "お");
    is($data->{bottom}, "か");
  }
}

# add_meta_title
{
  # add_meta_title - add meta title
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{title} = "TITLE";
    $data->{meta} = "あ";
    $api->add_meta_title($data);
    is($data->{meta}, "あ\n<title>TITLE</title>");
  }
}

# add_meta_description
{
  # add_meta_description - add meta description
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{description} = "Perl is good";
    $data->{meta} = "あ";
    $api->add_meta_description($data);
    is($data->{meta}, qq(あ\n<meta name="description" content="Perl is good">));
  }
}

# build_entry
{
  # build_entry - build_entry content by common templates
  {
    my $home_dir = 't/tmp/api/build_entry';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    
    $api->write_to_file("$home_dir/templates/common/top.html", "お");
    $api->write_to_file("$home_dir/templates/common/bottom.html", "か");

    my $data = {};
    $api->read_common_templates($data);
    
    is($data->{top}, "お");
    is($data->{bottom}, "か");
    
    $data->{content} = 'コンテンツ';
    $api->build_entry($data);
    
    my $expect =<<'EOS';
<div class="entry">
  <div class="top">
    お
  </div>
  <div class="middle">
    コンテンツ
  </div>
  <div class="bottom">
    か
  </div>
</div>
EOS
    is($data->{content}, $expect);
  }
}

# build_html
{
  # build_html - build_html content by common templates
  {
    my $home_dir = 't/tmp/api/build_html';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    
    $api->write_to_file("$home_dir/templates/common/meta.html", "あ");
    $api->write_to_file("$home_dir/templates/common/header.html", "い");
    $api->write_to_file("$home_dir/templates/common/footer.html", "う");
    $api->write_to_file("$home_dir/templates/common/side.html", "え");
    $api->write_to_file("$home_dir/templates/common/top.html", "お");
    $api->write_to_file("$home_dir/templates/common/bottom.html", "か");

    my $data = {};
    $api->read_common_templates($data);
    
    is($data->{meta}, "あ");
    is($data->{header}, "い");
    is($data->{footer}, "う");
    is($data->{side}, "え");
    is($data->{top}, "お");
    is($data->{bottom}, "か");
    
    $data->{content} = 'コンテンツ';

    $api->build_entry($data);
    $api->build_html($data);
    
    my $expect =<<'EOS';
<!DOCTYPE html>
<html>
  <head>
    あ
  </head>
  <body>
    <div class="container">
      <div class="header">
        い
      </div>
      <div class="main">
        <div class="content">
          <div class="entry">
  <div class="top">
    お
  </div>
  <div class="middle">
    コンテンツ
  </div>
  <div class="bottom">
    か
  </div>
</div>

        </div>
        <div class="side">
          え
        </div>
      </div>
      <div class="footer">
        う
      </div>
    </div>
  </body>
</html>
EOS
    is($data->{content}, $expect);
  }
}

# write_to_public_file
{
  # write_to_public_file - write content to public directory
  {
    my $home_dir = 't/tmp/api/write_to_public_file';
    rmtree $home_dir;
    my $giblog = Giblog->new(home_dir => $home_dir);
    my $api = Giblog::API->new(giblog => $giblog);
    my $module_name = 'Giblog::Command::new';
    $api->create_website_from_proto($home_dir, $module_name);
    my $data = {};
    $data->{file} = 'index.html';
    $data->{content} = 'あ';
    $api->write_to_public_file($data);
    open my $fh, '<', "$home_dir/public/index.html"
      or die "Can't open file";
    my $content = do { local $/; <$fh> };
    $content = decode('UTF-8', $content);
    is($content, 'あ');
  }
}

# replace_vars
{
  # replace_vars
  {
    my $giblog = Giblog->new;
    my $api = Giblog::API->new(giblog => $giblog);
    my $data = {};
    $data->{content} = '<p><%= $giblog_test_variable %></p><p><%=  $giblog_test_variable  %></p>';
    $giblog->{config} = {};
    $api->config->{vars}{'$giblog_test_variable'} = 'Foo';
    $api->replace_vars($data);
    my $content = $data->{content};
    is($content, "<p>Foo</p><p>Foo</p>");
  }
}
