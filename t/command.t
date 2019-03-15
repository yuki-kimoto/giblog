use strict;
use warnings;
use Test::More 'no_plan';

use File::Path 'mkpath', 'rmtree';

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
  my $home_dir = "$test_dir/mysite_new";
  {
    my $cmd = "$^X -Mblib blib/script/giblog add --home=$home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
  }
  sleep 2;
  {
    my $cmd = "$^X -Mblib blib/script/giblog add --home=$home_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
  }
  
  my @files = glob "$home_dir/templates/blog/*";
  
  is(scalar @files, 2);
  like($files[0], qr/\d{14}\.html/);
  like($files[1], qr/\d{14}\.html/);
}
