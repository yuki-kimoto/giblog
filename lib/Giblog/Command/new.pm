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
  
  my $api = $self->api;
  
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
  my $command_proto_dir = $api->command_rel_file($self, 'proto');

  # Create website directory
  $api->create_dir($website_name);

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
}

1;
