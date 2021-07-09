package Giblog::Command::serve;

use base 'Giblog::Command';

use strict;
use warnings;
use Mojolicious;

use Carp 'confess';

sub run {
  my ($self) = @_;
  
  my $command = 'morbo -w giblog.conf -w lib -w templates serve.pl';
  
  system($command) == 0
    or confess "Can't serve serve.pl";
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::serve - Website serve command

=head1 DESCRIPTION

L<Giblog::Command::serve> is website serve command.

=head1 METHODS

L<Giblog::Command::serve> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run;

Serve website starting up C<serve.pl> using L<morbo> command of L<Mojolicious>.

Same as the following command.

  morbo -w giblog.conf -w lib -w templates serve.pl
