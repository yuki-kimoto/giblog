package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

use Carp 'confess';

sub run {
  confess "Not inplemented"
}

1;

=head1 NAME

Giblog::Command::build - build command

=head1 METHODS

L<Giblog::Command::build> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run(@argv);

Execute build command.
