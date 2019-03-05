package Giblog::Command::new_blog;

use base 'Giblog::Command::new';

use strict;
use warnings;

sub run { shift->SUPER::new(@_) }

1;

=head1 NAME

Giblog::Command::new_blog - new_blog command

=head1 METHODS

L<Giblog::Command::new_blog> inherits all methods from L<Giblog::Command::new> and
implements the following new ones.

=head2 run

  $command->run(@argv);

Execute new_blog command.
