package Giblog::Command;

use strict;
use warnings;
use Carp 'confess';

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, ref $class || $class;
}

sub api { shift->{api} }

sub run { confess 'Method "run" not implemented by subclass' }

1;

=head1 NAME

Giblog::Command - command base class

=head1 METHODS

=head2 new

  $command->new(%args);

Create command object.

=head2 api

  $command->api;

Get L<Giblog::API> object.

=head2 run

  $command->run(@args);

Run command. This method is implemented by subclass
