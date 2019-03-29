use strict;
use warnings;
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
  
  return $content;
}

# proto/new
{
  # proto/new - new, add, build
  {
    my $home_dir = "$test_dir/mysite_new";
    rmtree $home_dir;
    my $new_cmd = "$^X -Mblib blib/script/giblog new $home_dir";
    system($new_cmd) == 0
      or die "Can't execute command $new_cmd:$!";
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
    is(scalar @blog_files, 1);
    
    my $index_content = slurp $index_file;
    my $blog_content = slurp $blog_files[0];
    
    like($index_content, qr/header/);
    like($index_content, qr/footer/);
    like($index_content, qr/top/);
    like($index_content, qr/bottom/);
    like($index_content, qr/meta/);
    like($index_content, qr/<p>/);
    like($index_content, qr|</p>|);
    like($index_content, qr/Content1/);
    like($index_content, qr/Content2/);
    like($index_content, qr/&gt;/);
    like($index_content, qr/&lt;/);
    like($index_content, qr/&lt;/);
    like($index_content, qr|<title>Title</title>|);
    like($index_content, qr|<h2><a href="/">Title</a></h2>|);

    like($blog_content, qr/header/);
    like($blog_content, qr/footer/);
    like($blog_content, qr/top/);
    like($blog_content, qr/bottom/);
    like($blog_content, qr/meta/);
    
    # CGI file
    if ($^O eq 'linux') {
      ok(-x "$home_dir/templates/static/test.cgi");
      ok(-x "$home_dir/public/test.cgi");
    }
  }
}

