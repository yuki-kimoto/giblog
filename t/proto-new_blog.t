use strict;
use warnings;
use utf8;
use Encode 'decode';

use Test::More 'no_plan';

use File::Path 'mkpath', 'rmtree';
use Cwd 'getcwd';
use File::Basename 'basename';

my $giblog_dir = '../../../..';
my $test_dir = 't/tmp/command';

sub slurp {
  my $file = shift;
  
  open my $fh, '<', $file
    or die "Can't open $file: $!";
  
  my $content = do { local $/; <$fh> };

  $content = decode('UTF-8', $content);
  
  return $content;
}

# proto/new_blog
{
  # proto/new_blog - new_blog, add, build
  {
    my $home_dir = "$test_dir/mysite_new_blog";
    rmtree $home_dir;
    my $new_blog_cmd = "$^X -Mblib blib/script/giblog new_blog $home_dir";
    system($new_blog_cmd) == 0
      or die "Can't execute command $new_blog_cmd:$!";
    my $save_cur_dir = getcwd;
    {
      my $add_cmd = "$^X -Mblib blib/script/giblog add --home $home_dir";
      system($add_cmd) == 0
        or die "Can't execute command $add_cmd:$!";
    }
    {
      my $build_cmd = "$^X -Mblib blib/script/giblog build -H $home_dir";
      system($build_cmd) == 0
        or die "Can't execute command $build_cmd:$!";
    }

    my @blog_files = reverse glob "$home_dir/public/blog/*";
    is(scalar @blog_files, 9);
    
    # Added Blog
    my $added_blog_file = $blog_files[0];
    my $added_blog_file_base = basename $added_blog_file;
    
    # Blog
    {
      my $blog_file = "$home_dir/public/blog/20190319121234.html";
      my $blog_content = slurp $blog_file;
      
      like($blog_content, qr/header/);
      like($blog_content, qr/footer/);
      like($blog_content, qr/top/);
      like($blog_content, qr/bottom/);
      like($blog_content, qr/meta/);
      like($blog_content, qr|<p>\s*How to use Giblog\.\s*</p>|);
      like($blog_content, qr/&gt;/);
      like($blog_content, qr/&lt;/);
      like($blog_content, qr/&amp;/);
      like($blog_content, qr|<title>How to use Giblog😁 - mysite😄</title>|);
      like($blog_content, qr|<h2><a href="/blog/20190319121234.html">How to use Giblog😁</a></h2>|);
      like($blog_content, qr|\Qside-list|);
      like($blog_content, qr|\Q<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">|);
      like($blog_content, qr|\Q<meta name="description" content="How to use Giblog.">|);
      like($blog_content, qr|\Q<link rel="stylesheet" type="text/css" href="/css/common.css">|);
    }
    
    # Index
    {
      my $index_file = "$home_dir/public/index.html";
      my $index_content = slurp $index_file;
      
      like($index_content, qr/header/);
      like($index_content, qr/footer/);
      like($index_content, qr/top/);
      like($index_content, qr/bottom/);
      like($index_content, qr/meta/);
      like($index_content, qr|<p>\s*How to use Giblog\.\s*</p>|);
      like($index_content, qr/&gt;/);
      like($index_content, qr/&lt;/);
      like($index_content, qr/&amp;/);
      like($index_content, qr|<title>mysite😄</title>|);
      like($index_content, qr|<h1>\s*<a href="/">Giblog Web Site</a>\s*</h1>|);
      like($index_content, qr|<h2><a href="/blog/20190319121234.html">How to use Giblog😁</a></h2>|);
      like($index_content, qr|\Qside-list|);
      like($index_content, qr|\Q<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">|);
      like($index_content, qr|\Q<meta name="description" content="Site description">|);
      like($index_content, qr|\Q<link rel="stylesheet" type="text/css" href="/css/common.css">|);
      like($index_content, qr|\Q<a href="https://github.com/yuki-kimoto/giblog">Giblog</a>|);
      
      like($index_content, qr/Hello Giblog 7/);
      like($index_content, qr/Hello Giblog 6/);
      like($index_content, qr/Hello Giblog 5/);
      like($index_content, qr/Hello Giblog 4/);
      like($index_content, qr/Hello Giblog 3/);
      unlike($index_content, qr/Hello Giblog 2/);
      unlike($index_content, qr/Hello Giblog 1/);
    }

    # List
    {
      my $list_file = "$home_dir/public/list.html";
      my $list_content = slurp $list_file;
      like($list_content, qr/header/);
      like($list_content, qr/footer/);
      like($list_content, qr/top/);
      like($list_content, qr/bottom/);
      like($list_content, qr/meta/);
      like($list_content, qr|<title>Entries - mysite😄</title>|);
      like($list_content, qr|<h2><a href="/list.html">Entries</a></h2>|);
      like($list_content, qr|\Qside-list|);
      like($list_content, qr|\Q<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">|);
      like($list_content, qr|\Q<meta name="description" content="Entries of mysite😄">|);
      like($list_content, qr|\Q<link rel="stylesheet" type="text/css" href="/css/common.css">|);
      
      like($list_content, qr|\Q$added_blog_file_base|);
      like($list_content, qr|3/19 <a href="/blog/20190319121234.html">How to use Giblog😁</a>|);
      like($list_content, qr|3/18 <a href="/blog/20190318121234.html">Hello Giblog 7</a>|);
      like($list_content, qr|3/17 <a href="/blog/20190317121234.html">Hello Giblog 6</a>|);
      like($list_content, qr|3/16 <a href="/blog/20190316121234.html">Hello Giblog 5</a>|);
      like($list_content, qr|3/15 <a href="/blog/20190315121234.html">Hello Giblog 4</a>|);
      like($list_content, qr|3/14 <a href="/blog/20190314121234.html">Hello Giblog 3</a>|);
      like($list_content, qr|3/13 <a href="/blog/20190313121234.html">Hello Giblog 2</a>|);
      like($list_content, qr|12/1 <a href="/blog/20181201121234.html">Hello Giblog 1</a>|);
    }
    # CGI file
    if ($^O eq 'linux') {
      ok(-x "$home_dir/templates/static/test.cgi");
      ok(-x "$home_dir/public/test.cgi");
    }
  }
}

