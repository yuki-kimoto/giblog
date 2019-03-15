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

# New
{
  # new command
  {
    my $home_dir = "$test_dir/mysite_new";
    my $cmd = "$^X -Mblib blib/script/giblog new $home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$home_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$home_dir/README",
        "$home_dir/giblog.conf",
        "$home_dir/lib",
        "$home_dir/public",
        "$home_dir/serve.pl",
        "$home_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$home_dir/README";
    like($readme_content, qr|Giblog/Command/new/proto|);
  }

  # new_hp command
  {
    my $home_dir = "$test_dir/mysite_new_hp";
    my $cmd = "$^X -Mblib blib/script/giblog new_hp $home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$home_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$home_dir/README",
        "$home_dir/giblog.conf",
        "$home_dir/lib",
        "$home_dir/public",
        "$home_dir/serve.pl",
        "$home_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$home_dir/README";
    like($readme_content, qr|Giblog/Command/new_hp/proto|);
  }

  # new_blog command
  {
    my $home_dir = "$test_dir/mysite_new_blog";
    my $cmd = "$^X -Mblib blib/script/giblog new_blog $home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$home_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$home_dir/README",
        "$home_dir/giblog.conf",
        "$home_dir/lib",
        "$home_dir/public",
        "$home_dir/serve.pl",
        "$home_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$home_dir/README";
    like($readme_content, qr|Giblog/Command/new_blog/proto|);
  }

  # new_zemi command
  {
    my $home_dir = "$test_dir/mysite_new_zemi";
    my $cmd = "$^X -Mblib blib/script/giblog new_zemi $home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$home_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$home_dir/README",
        "$home_dir/giblog.conf",
        "$home_dir/lib",
        "$home_dir/public",
        "$home_dir/serve.pl",
        "$home_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$home_dir/README";
    like($readme_content, qr|Giblog/Command/new_zemi/proto|);
  }
}

# add
{
  # add - change directory
  {
    my $home_dir = "$test_dir/mysite_new";
    rmtree $home_dir;
    my $new_cmd = "$^X -Mblib blib/script/giblog new $home_dir";
    system($new_cmd) == 0
      or die "Can't execute command $new_cmd:$!";
    my $save_cur_dir = getcwd;
    chdir $home_dir
      or die "Can't change directory";
    {
      my $add_cmd = "$^X -Mblib $giblog_dir/blib/script/giblog add";
      system($add_cmd) == 0
        or die "Can't execute command $add_cmd:$!";
    }
    sleep 2;
    {
      my $add_cmd = "$^X -Mblib $giblog_dir/blib/script/giblog add";
      system($add_cmd) == 0
        or die "Can't execute command $add_cmd:$!";
    }
    chdir $save_cur_dir
      or die "Can't back to saved current directory";
    
    my @files = glob "$home_dir/templates/blog/*";
    
    is(scalar @files, 2);
    like($files[0], qr/\d{14}\.html/);
    like($files[1], qr/\d{14}\.html/);
  }

  # add - --home option
  {
    my $home_dir = "$test_dir/mysite_new";
    rmtree $home_dir;
    my $new_cmd = "$^X -Mblib blib/script/giblog new $home_dir";
    system($new_cmd) == 0
      or die "Can't execute command $new_cmd:$!";
    
    {
      my $add_cmd = "$^X -Mblib blib/script/giblog add --home=$home_dir";
      system($add_cmd) == 0
        or die "Can't execute command $add_cmd:$!";
    }
    my @files = glob "$home_dir/templates/blog/*";
    
    is(scalar @files, 1);
    like($files[0], qr/\d{14}\.html/);
  }
}
