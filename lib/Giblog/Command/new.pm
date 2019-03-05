package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @argv) = @_;
  
  my $website_name = shift @argv;

  my $api = $self->api;
  
  my $module_name = ref $self;
  
  my $proto_dir = $api->get_proto_dir($module_name);
  
  $api->create_website($website_name, $proto_dir);
}

1;

=head1 NAME

Giblog::Command::new - new command

=head1 DESCRIPTION

=head1 METHODS

L<Giblog::Command::new> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run(@argv);

Execute command.
