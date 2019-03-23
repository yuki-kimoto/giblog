package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @argv) = @_;
  
  my $website_name = shift @argv;

  my $api = $self->api;
  
  my $module_name = ref $self;
  
  $api->create_website_from_proto($website_name, $module_name);
}

1;

=head1 NAME

Giblog::Command::new - new command

=head1 METHODS

L<Giblog::Command::new> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run(@argv);

Execute new command.
