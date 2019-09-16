use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;

# Build
my $cmd = 'giblog build';
system($cmd) == 0
  or die "Can't execute $cmd: $!";

# Read config file
my $config_file = "$FindBin::Bin/giblog.conf";
my $config;
$config = do $config_file
  or die "Can't read config file $config_file";

use Mojolicious::Lite;

# Remove base path before dispatch
my $base_path = $config->{base_path};
if (defined $base_path) {
  
  # Subdir depth
  my @parts = File::Spec->splitdir($base_path);
  my $subdir_depth = @parts - 1;
  
  app->hook(before_dispatch => sub {
    my $self = shift;
    
    # Remove base path
    for (my $i = 0; $i < $subdir_depth; $i++) {
      shift @{$self->req->url->path->parts};
    }
  });
}

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
