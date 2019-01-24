package Giblog::Plugin::new;

use base 'Giblog::Plugin';

use strict;
use warnings;

use Carp 'confess';

use File::Path 'mkpath';
use File::Copy 'copy';
use File::Basename 'dirname';
use File::Find 'find';

sub plugin {
  my ($self, $website_name) = @_;
  
  my $giblog = $self->giblog;
  
  unless (defined $website_name) {
    die "Website name must be specifed\n";
  }
  if ($website_name !~ /^[a-zA-Z0-9_\-]+$/) {
    die "Website name \"$website_name\" is invalid\n";
  }
  
  if (-f $website_name) {
    die "Website \"$website_name\" is already exists\n";
  }
  
  my $plugin_class = ref $self;
  my $plugin_proto_dir = $giblog->plugin_rel_file($self, 'proto');

  # Create website directory
  $giblog->create_dir($website_name);
  
  # Create giblog.conf
  my $config_file = "$website_name/giblog.conf";
  $giblog->create_file($config_file);
  my $config = <<"EOS";
{
  site_title => "Web Site Name",
}
EOS
  $giblog->write_to_file($config_file, $config);

  # Create web application
  my $webapp_file = "$website_name/webapp";
  $giblog->create_file($webapp_file);
  my $webapp = <<'EOS';
#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
my $giblog_dir;
BEGIN {
  $giblog_dir = dirname __FILE__;
}
use lib "$giblog_dir/lib";
use Giblog;
use Giblog::Plugin::build;

my $giblog = Giblog->new('giblog-dir' => $giblog_dir);
my $build_plugin = Giblog::Plugin::build->new(giblog => $giblog);
$build_plugin->plugin;

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
EOS
  $giblog->write_to_file($webapp_file, $webapp);

  # Create build plugin
  mkpath "$website_name/lib/Giblog/Plugin";
  my $build_plugin_file = "$website_name/lib/Giblog/Plugin/build.pm";
  $giblog->create_file($build_plugin_file);
  my $build_plugin = <<'EOS';
package Giblog::Plugin::build;

use base 'Giblog::Plugin::base_build';

use strict;
use warnings;

sub plugin {
  my ($self, @args) = @_;
  
  # Write pre process
  
  $self->SUPER::plugin(@args);
  
  # Write post porsess
}

1;
EOS
  $giblog->write_to_file($build_plugin_file, $build_plugin);

  # Copy plugin proto files to user directory
  my @files;
  find(
    {
      wanted => sub {
        my $plugin_proto_file = $File::Find::name;
        
        # Skip directory
        return unless -f $plugin_proto_file;
        
        my $rel_file = $plugin_proto_file;
        $rel_file =~ s/^\Q$plugin_proto_dir\E[\/|\\]//;
        
        my $user_file = "$website_name/$rel_file";
        my $user_dir = dirname $user_file;
        mkpath $user_dir;
        
        copy $plugin_proto_file, $user_file
          or confess "Can't copy $plugin_proto_file to $user_file: $!";
      },
      no_chdir => 1,
    },
    $plugin_proto_dir
  );
}

1;
