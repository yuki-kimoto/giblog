use strict;
use warnings;
use utf8;
use Encode 'decode', 'encode';

use Test::More 'no_plan';

use File::Path 'mkpath', 'rmtree';
use Cwd 'getcwd';

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

sub add_config_file {
  my ($file, $value) = @_;
  
  open my $in_fh, '<', $file
    or die "Can't open $file: $!";
  
  my $content = do { local $/; <$in_fh> };
  
  $content = decode('UTF-8', $content);
  
  $content =~ s/}/$value}/;
  
  close $in_fh;
  
  unlink $file;
  
  open my $out_fh, '>', $file
    or die "Can't open $file: $!";
  
  print $out_fh encode('UTF-8', $content);
}

# proto/new_website
{
  # proto/new_website with base_path option
  {
    my $home_dir = "$test_dir/mysite_base_path";
    rmtree $home_dir;
    my $new_website_cmd = "$^X -Mblib blib/script/giblog new_website $home_dir";
    system($new_website_cmd) == 0
      or die "Can't execute command $new_website_cmd:$!";
    
    # add base_path to config
    my $config_file = "$home_dir/giblog.conf";
    add_config_file($config_file, qq(  base_path => '/subdir',\n));
    
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
    
    my $index_file = "$home_dir/public/index.html";
    my @blog_files = glob "$home_dir/public/blog/*";
    is(scalar @blog_files, 9);
    
    my $index_content = slurp $index_file;
    my $blog_content = slurp $blog_files[0];
    
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
    like($index_content, qr|<h1>\s*<a href="/subdir/">Giblog Web Site</a>\s*</h1>|);
    like($index_content, qr|<h2><a href="/subdir/">How to use Giblog😁</a></h2>|);
    like($index_content, qr|\Qside_list|);
    like($index_content, qr|\Q<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">|);
    like($index_content, qr|\Q<meta name="description" content="How to use Giblog.">|);
    like($index_content, qr|\Q<link rel="stylesheet" type="text/css" href="/subdir/css/common.css">|);
    like($index_content, qr|\bsrc="/subdir/images/logo.png\b|);
    like($blog_content, qr/header/);
    like($blog_content, qr/footer/);
    like($blog_content, qr/top/);
    like($blog_content, qr/bottom/);
    like($blog_content, qr/meta/);
    like($index_content, qr|\Q<a href="https://github.com/yuki-kimoto/giblog">Giblog</a>|);
    
    # css/common.css
    my $common_css_file = "$home_dir/public/css/common.css";
    my $common_css_content = slurp($common_css_file);
    like($common_css_content, qr|\b\Qurl(/subdir/images/logo.png|);
  }
}
