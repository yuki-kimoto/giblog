use strict;
use warnings;
use Test::More 'no_plan';

use File::Path 'mkpath', 'rmtree';
use Cwd 'getcwd';

my $giblog_dir = '../../../..';
my $test_dir = 't/tmp/command';

rmtree $test_dir;
mkpath $test_dir;

sub slurp {
  my $file = shift;
  
  open my $fh, '<', $file
    or die "Can't open $file: $!";
  
  my $content = do { local $/; <$fh> };
  
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
      my $build_cmd = "$^X -Mblib blib/script/giblog build -h $home_dir";
      system($build_cmd) == 0
        or die "Can't execute command $build_cmd:$!";
    }

    my @blog_files = glob "$home_dir/public/blog/*";
    is(scalar @blog_files, 9);
    
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
      like($blog_content, qr|<title>How to use Giblog</title>|);
      like($blog_content, qr|<h2><a href="/blog/20190319121234.html">How to use Giblog</a></h2>|);
      like($blog_content, qr|\Qside-list|);
      like($blog_content, qr|\Q<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">|);
      like($blog_content, qr|\Q<meta name="description" content="How to use Giblog.">|);
      like($blog_content, qr|\Q<link rel="stylesheet" type="text/css" href="/css/common.css">|);
    }
  }
}

