package Giblog::Command;

use strict;
use warnings;

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, ref $class || $class;
}

sub api { shift->{api} }

1;

=head1 NAME

Giblog::Command - command

=head1 METHODS

=head2 new

  $command->new(%args);

Create command object.

=head2 api

  $command->api;

Get L<Giblog::API> object.
