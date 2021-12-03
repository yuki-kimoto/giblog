package Giblog::Command::deploy;

use base 'Giblog::Command';

use strict;
use warnings;
use Mojolicious;
use Time::Piece 'localtime';
use Getopt::Long 'GetOptions';

use Carp 'confess';

sub run {
  my ($self, @argv) = @_;

  my $api = $self->api;

  my $deploy_perl_program = $api->rel_file('deploy.pl');
  
  my @execute_deploy_perl_program = ("$^X", $deploy_perl_program, @argv);
  if (system(@execute_deploy_perl_program) == -1) {
    confess "Fail executing the deployment program : @execute_deploy_perl_program : $?";
  }
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::deploy - Deployment Command

=head1 DESCRIPTION

L<Giblog::Command::deploy> is a command to deploy web sites.

=head1 METHODS

L<Giblog::Command::deploy> inherits all methods from L<Giblog::Command> and
implements the following deploy ones.

=head2 run

  $command->run(@argv);

C<deploy> command execute C<deploy.pl> in the home directory.

You can write any deployment process in C<deploy.pl>.

Command line arguments except the ones Giblog uses are passed to C<deploy> command.
