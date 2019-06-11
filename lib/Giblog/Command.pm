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

=encoding utf8

=head1 NAME

Giblog::Command - command base class

=head1 DESCRIPTION

L<Giblog::Command> is command base class.

You can also create your command inheriting L<Giblog::Command> like L<Giblog::Command::new>, L<Giblog::Command::add> or L<Giblog::Command::build>.

=head1 METHODS

=head2 new

  $command->new(%args);

Create command object.

Arguments:

=over 2

=item * api

L<Giblog::API> object.

=back

=head2 api

  $command->api;

Get L<Giblog::API> object.

=head2 run

  $command->run(@args);

Run command. This method is implemented by subclass.
