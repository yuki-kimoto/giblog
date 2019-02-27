package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

use Carp 'confess';

use File::Path 'mkpath';
use File::Copy 'copy';
use File::Basename 'dirname';
use File::Find 'find';

sub run {
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
  
  my $command_class = ref $self;
  my $command_proto_dir = $giblog->command_rel_file($self, 'proto');

  # Create website directory
  $giblog->create_dir($website_name);

  # Copy command proto files to user directory
  my @files;
  find(
    {
      wanted => sub {
        my $command_proto_file = $File::Find::name;
        
        # Skip directory
        return unless -f $command_proto_file;
        
        my $rel_file = $command_proto_file;
        $rel_file =~ s/^\Q$command_proto_dir\E[\/|\\]//;
        
        my $user_file = "$website_name/$rel_file";
        my $user_dir = dirname $user_file;
        mkpath $user_dir;
        
        copy $command_proto_file, $user_file
          or confess "Can't copy $command_proto_file to $user_file: $!";
      },
      no_chdir => 1,
    },
    $command_proto_dir
  );
  
  # Create giblog.conf
  my $config_file = "$website_name/giblog.conf";
  unless (-f $config_file) {
    $giblog->create_file($config_file);
    my $config = <<"EOS";
{
  site_title => 'Web Site Name',
  site_url => 'http://somesite.example',
}
EOS
    $giblog->write_to_file($config_file, $config);
  }
  
  # Create web application
  my $webapp_file = "$website_name/webapp";
  unless (-f $webapp_file) {
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
use Giblog::Command::build;

print "Server start\n";

my $giblog = Giblog->new('giblog-dir' => $giblog_dir);
my $build_command = Giblog::Command::build->new(giblog => $giblog);
$build_command->run;

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
EOS
    $giblog->write_to_file($webapp_file, $webapp);
  }
  
  # Create build command
  mkpath "$website_name/lib/Giblog/Command";
  my $build_command_file = "$website_name/lib/Giblog/Command/build.pm";
  unless (-f $build_command_file) {
    $giblog->create_file($build_command_file);
    my $build_command = <<'EOS';
package Giblog::Command::build;

use base 'Giblog::Command::base_build';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  # Write pre run
  
  $self->SUPER::run(@args);
  
  # Write post run
}

sub build_html {
  my ($self, $data) = @_;
  
  # Write pre build_html
  
  $self->SUPER::build_html($data);
  
  # Write post build_html
}

1;
EOS
    $giblog->write_to_file($build_command_file, $build_command);
  }
}

1;
