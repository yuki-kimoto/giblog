package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

use Carp 'confess';

sub run {
  confess "Not inplemented"
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::build - Website building command

=head1 DESCRIPTION

L<Giblog::Command::build> is website building command.

=head1 METHODS

L<Giblog::Command::build> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run;

Build website.

This method is planed to be overridden in subclass.
