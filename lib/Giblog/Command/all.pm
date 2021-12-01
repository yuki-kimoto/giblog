package Giblog::Command::all;

use base 'Giblog::Command';

use strict;
use warnings;
use Mojolicious;
use Time::Piece 'localtime';
use Getopt::Long 'GetOptions';

use Carp 'confess';

sub run {
  my ($self, @argv) = @_;
  
  my $message;
  {
    local @ARGV = @argv;
    my $getopt_option_all = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
    GetOptions(
      'm=s' => \$message,
    );
    Getopt::Long::Configure($getopt_option_all);
    @argv = @ARGV;
  }
  my ($remote_rep, $branch) = @argv;
  
  my $api = $self->api;

  my $home_dir = $api->rel_file('.');
  
  unless (defined $message) {
    confess 'Must be specify message using -m option';
  }

  unless (defined $remote_rep) {
    confess 'Must be specify remote repository name';
  }

  unless (defined $branch) {
    confess 'Must be specify branch name';
  }
  
  my @giblog_build_command = ('giblog', '-C', $home_dir, 'build');
  if (system(@giblog_build_command) == -1) {
    confess "Fail giblog all command. Command is @giblog_build_command: $?";
  }
  my @giblog_save_command = ('giblog', '-C', $home_dir, 'save', '-m', $message, $remote_rep, $branch);
  if(system(@giblog_save_command) == -1) {
    confess "Fail giblog all command. Command is @giblog_save_command : $?";
  }
  my @giblog_publish_command = ('giblog', '-C', $home_dir, 'publish', $remote_rep, $branch);
  if (system(@giblog_publish_command) == -1) {
    confess "Fail giblog all command. Command is @giblog_publish_command : $?";
  }
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::all - all command

=head1 DESCRIPTION

L<Giblog::Command::all> is all command to execute "giblog build", "giblog save", and "giblog publish".

=head1 METHODS

L<Giblog::Command::all> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run('-m', $message, $remote_repository, $branch);

all command executes the following git commands(giblog build, giblog save, giblog publish).

This is the same as the following command. In this example, the commit message is "Hello". the repository name is "origin". the branch name is "main".

  giblog build
  giblog save -m "Hello" origin main
  giblog publish origin main
