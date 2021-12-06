use strict;
use warnings;
use Test::More 'no_plan';

use File::Path 'mkpath', 'rmtree';
use Cwd 'getcwd';
use Time::HiRes 'sleep';

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
    
    my $public_index_file = "$home_dir/public/index.html";
    my @blog_files = glob "$home_dir/public/blog/*";
    is(scalar @blog_files, 1);
    
    my $index_content = slurp $public_index_file;
    my $blog_content = slurp $blog_files[0];

    
    my $static_css_file = "$home_dir/templates/static/css/common.css";
    ok(-f $static_css_file);
    my $public_css_file = "$home_dir/public/css/common.css";
    ok(-f $public_css_file);
    
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
    
    like($index_content, qr|<p>Giblog Test Variable</p><p>Giblog Test Variable</p>|);

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
    
    # Check git directory
    ok(-d "$home_dir/.git");
    ok(-d "$home_dir/public/.git");
    
    # Static files are the same modified time as public files
    is(-M $static_css_file, -M $public_css_file);
    
    # Rebuild - no change
    {
      # File time and size - template files and static files
      {
        # Original time
        my $original_index_time = -M $public_index_file;

        my $static_css_file_time = -M $static_css_file;
        my $public_css_file_time_original = -M $public_css_file;
        
        my $build_cmd = "$^X -Mblib blib/script/giblog build -H $home_dir";
        system($build_cmd) == 0
          or die "Can't execute command $build_cmd:$!";
          
        my $current_index_time = -M $public_index_file;
        is($original_index_time, $current_index_time);

        # Static files are the same modified time as public files
        is(-M $static_css_file, -M $public_css_file);
      }
    }

    # Rebuild - have change
    {
      # Original time
      my $original_index_time = -M $public_index_file;
      open my $public_index_fh, '>', $public_index_file
        or die "Can't open file $public_index_file: $!";
      print $public_index_fh "AAAA";
      close $public_index_fh;


      open my $static_css_file_fh, '>', $static_css_file
        or die "Can't open file $static_css_file: $!";
      print $static_css_file_fh "h1 { }";
      close $static_css_file_fh;
      my $static_css_file_time = -M $static_css_file;

      sleep 2;
      
      my $build_cmd = "$^X -Mblib blib/script/giblog build -H $home_dir";
      system($build_cmd) == 0
        or die "Can't execute command $build_cmd:$!";
        
      my $current_index_time = -M $public_index_file;
      isnt($original_index_time, $current_index_time);

      # Static files are the same modified time as public files
      is(-M $static_css_file, -M $public_css_file);
    }
  }
}

