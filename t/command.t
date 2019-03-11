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
