package Giblog::Command::new_hp;

use base 'Giblog::Command::new';

use strict;
use warnings;

sub run { shift->SUPER::run(@_) }

1;

=head1 NAME

Giblog::Command::new_hp - new_hp command

=head1 METHODS

L<Giblog::Command::new_hp> inherits all methods from L<Giblog::Command::new> and
implements the following new ones.

=head2 run

  $command->run(@argv);

Execute new_hp command.
