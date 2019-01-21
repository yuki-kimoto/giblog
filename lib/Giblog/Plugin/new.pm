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
  site_title => "$website_name",
}
EOS
  $giblog->write_to_file($config_file, $config);

  # Create development application
  my $devapp_file = "$website_name/devapp";
  $giblog->create_file($devapp_file);
  my $devapp = <<"EOS";
#!/usr/bin/env perl

my \$build_cmd = 'giblog build';
system(\$build_cmd) == 0
  or warn("Can't execute build command \$build_cmd:\$!");

use Mojolicious::Lite;

get '/' => sub {
  my \$c = shift;
  
  \$c->reply->static('index.html');
};

app->start;
EOS
  $giblog->write_to_file($devapp_file, $devapp);

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
