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
    my $website_dir = "$test_dir/mysite_new";
    my $cmd = "$^X -Mblib blib/script/giblog new $website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$website_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$website_dir/README",
        "$website_dir/giblog.conf",
        "$website_dir/lib",
        "$website_dir/public",
        "$website_dir/serve.pl",
        "$website_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$website_dir/README";
    like($readme_content, qr|Giblog/Command/new/proto|);
  }

  # new_hp command
  {
    my $website_dir = "$test_dir/mysite_new_hp";
    my $cmd = "$^X -Mblib blib/script/giblog new_hp $website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$website_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$website_dir/README",
        "$website_dir/giblog.conf",
        "$website_dir/lib",
        "$website_dir/public",
        "$website_dir/serve.pl",
        "$website_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$website_dir/README";
    like($readme_content, qr|Giblog/Command/new_hp/proto|);
  }

  # new_blog command
  {
    my $website_dir = "$test_dir/mysite_new_blog";
    my $cmd = "$^X -Mblib blib/script/giblog new_blog $website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$website_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$website_dir/README",
        "$website_dir/giblog.conf",
        "$website_dir/lib",
        "$website_dir/public",
        "$website_dir/serve.pl",
        "$website_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$website_dir/README";
    like($readme_content, qr|Giblog/Command/new_blog/proto|);
  }

  # new_zemi command
  {
    my $website_dir = "$test_dir/mysite_new_zemi";
    my $cmd = "$^X -Mblib blib/script/giblog new_zemi $website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
    
    my @files = sort glob "$website_dir/*";
    
    is_deeply(
      \@files, 
      [
        "$website_dir/README",
        "$website_dir/giblog.conf",
        "$website_dir/lib",
        "$website_dir/public",
        "$website_dir/serve.pl",
        "$website_dir/templates",
      ]
    );
    
    my $readme_content = slurp "$website_dir/README";
    like($readme_content, qr|Giblog/Command/new_zemi/proto|);
  }
}

# add
{
  my $website_dir = "$test_dir/mysite_new";
  {
    my $cmd = "$^X -Mblib blib/script/giblog add --giblog-dir=$website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
  }
  sleep 2;
  {
    my $cmd = "$^X -Mblib blib/script/giblog add --giblog-dir=$website_dir";
    system($cmd) == 0
      or die "Can't execute command $cmd:$!";
  }
  
  my @files = glob "$website_dir/templates/blog/*";
  
  is(scalar @files, 2);
  like($files[0], qr/\d{14}\.html/);
  like($files[1], qr/\d{14}\.html/);
}
