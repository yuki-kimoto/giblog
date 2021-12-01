package Giblog::Command::save;

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
    my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
    GetOptions(
      'm=s' => \$message,
    );
    Getopt::Long::Configure($getopt_option_save);
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
  
  my @git_add_command = ('git', '-C', $home_dir, 'add', '--all');
  if (system(@git_add_command) == -1) {
    confess "Fail giblog save command. Command is @git_add_command: $?";
  }
  my @git_commit_command = ('git', '-C', $home_dir, 'commit', '-m', $message);
  if(system(@git_commit_command) == -1) {
    confess "Fail giblog save command. Command is @git_commit_command : $?";
  }
  my @git_push_command = ('git', '-C', $home_dir, 'push', $remote_rep, $branch);
  if (system(@git_push_command) == -1) {
    confess "Fail giblog save command. Command is @git_push_command : $?";
  }
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::save - save command

=head1 DESCRIPTION

L<Giblog::Command::save> is save command.

=head1 METHODS

L<Giblog::Command::save> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run('-m', $message, $remote_repository, $branch);

save command executes the following git commands(add, commit, push).

This is the same as the following command. In this example, the commit message is "Hello". the repository name is "origin". the branch name is "main".

  git add --all
  git commit -m "Hello"
  git push origin main
