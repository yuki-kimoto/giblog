package Giblog::Command;

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

L<Giblog::Command> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 new

  $command->run(%args);

Create command object.

=head2 api

  $command->api;

Get L<Giblog::API> object.
