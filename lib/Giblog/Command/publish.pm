package Giblog::Command::publish;

use base 'Giblog::Command';

use strict;
use warnings;
use Mojolicious;
use Time::Piece 'localtime';
use Getopt::Long 'GetOptions';

use Carp 'confess';

sub run {
  my ($self, @argv) = @_;
  
  my $execute_build_command;
  {
    local @ARGV = @argv;
    my $getopt_option_all = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
    GetOptions(
      'build' => \$execute_build_command,
    );
    Getopt::Long::Configure($getopt_option_all);
    @argv = @ARGV;
  }
  my ($remote_rep, $branch) = @argv;
  
  my $api = $self->api;

  my $home_dir = $api->rel_file('.');
  my $public_dir = $api->rel_file('public');

  unless (defined $remote_rep) {
    confess 'Must be specify remote repository name';
  }

  unless (defined $branch) {
    confess 'Must be specify branch name';
  }
  
  if ($execute_build_command) {
    my @giblog_build_command = ('giblog', '-C', $home_dir, 'build');
    if (system(@giblog_build_command) == -1) {
      confess "Fail giblog publish command with --build option. Command is @giblog_build_command: $?";
    }
  }
  
  my @git_add_command = ('git', '-C', $public_dir, 'add', '--all');
  if (system(@git_add_command) == -1) {
    confess "Fail giblog publish command. Command is @git_add_command: $?";
  }
  my $now_tp = Time::Piece::localtime;
  my @git_commit_command = ('git', '-C', $public_dir, 'commit', '-m', '"Published by Giblog at ' . $now_tp->strftime('%Y-%m-%d %H:%M:%S') . '"');
  if(system(@git_commit_command) == -1) {
    confess "Fail giblog publish command. Command is @git_commit_command : $?";
  }
  my @git_push_command = ('git', '-C', $public_dir, 'push', '-f', $remote_rep, $branch);
  if (system(@git_push_command) == -1) {
    confess "Fail giblog publish command. Command is @git_push_command : $?";
  }
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::publish - Website publish command

=head1 DESCRIPTION

L<Giblog::Command::publish> is website publish command.

=head1 USAGE

  giblog publish REMOTE_REPOSITORY BRANCH
  
  giblog publish --build REMOTE_REPOSITORY BRANCH

=head1 METHODS

L<Giblog::Command::publish> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run($remote_repository, $branch);
  $command->run('--build', $remote_repository, $branch);

Publish your website by specifing remote repository name and branch name.

This is the same as the following command. In this example, the repository name is origin and the branch name is main. YY-mm-dd HH:MM:SS is current date and time.

  git -C public add --all
  git -C public commit -m "Published by Giblog at YY-mm-dd HH:MM:SS"
  git -C public push -f origin main

When you deploy this on the production environment, you can use the following command.
  
  # Deployment on production environment
  git fetch
  git reset --hard origin/main

If C<--build> option is specified, "giblog build" is executed before publishing.
