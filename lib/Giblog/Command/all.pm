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
  my $has_no_build_option;
  my $has_no_save_option;
  my $has_no_publish_option;
  my $has_no_deploy_option;
  {
    local @ARGV = @argv;
    my $getopt_option_all = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
    GetOptions(
      'm=s' => \$message,
      'no-build' => \$has_no_build_option,
      'no-save' => \$has_no_save_option,
      'no-publish' => \$has_no_publish_option,
      'no-deploy' => \$has_no_deploy_option,
    );
    Getopt::Long::Configure($getopt_option_all);
    @argv = @ARGV;
  }
  my ($remote_rep, $branch) = @argv;
  
  my $api = $self->api;

  my $home_dir = $api->rel_file('.');
  
  unless ($has_no_build_option) {
    my @giblog_build_command = ('giblog', '-C', $home_dir, 'build');
    if (system(@giblog_build_command) == -1) {
      confess "Fail giblog all command. Command is @giblog_build_command: $?";
    }
  }
  
  unless ($has_no_save_option) {
    my @giblog_save_command = ('giblog', '-C', $home_dir, 'save', '-m', $message, $remote_rep, $branch);
    if(system(@giblog_save_command) == -1) {
      confess "Fail giblog all command. Command is @giblog_save_command : $?";
    }
  }
  
  unless ($has_no_publish_option) {
    my @giblog_publish_command = ('giblog', '-C', $home_dir, 'publish', $remote_rep, $branch);
    if (system(@giblog_publish_command) == -1) {
      confess "Fail giblog all command. Command is @giblog_publish_command : $?";
    }
  }

  unless ($has_no_deploy_option) {
    my @giblog_deploy_command = ('giblog', '-C', $home_dir, 'deploy');
    if (system(@giblog_deploy_command) == -1) {
      confess "Fail giblog all command. Command is @giblog_deploy_command: $?";
    }
  }
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::all - all command

=head1 DESCRIPTION

L<Giblog::Command::all> is the command to execute "giblog build", "giblog save", "giblog publish", and "giblog deploy" at once.

=head1 USAGE

  giblog all -m COMMIT_COMMENT REMOTE_REPOSITORY BRANCH
  giblog all -m COMMIT_COMMENT --no-build REMOTE_REPOSITORY BRANCH
  giblog all -m COMMIT_COMMENT --no-save REMOTE_REPOSITORY BRANCH
  giblog all -m COMMIT_COMMENT --no-publish REMOTE_REPOSITORY BRANCH
  giblog all -m COMMIT_COMMENT --no-deploy REMOTE_REPOSITORY BRANCH
  
=head1 METHODS

L<Giblog::Command::all> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run('-m', $message, $remote_repository, $branch);
  $command->run('-m', $message, '--no-build', $remote_repository, $branch);
  $command->run('-m', $message, '--no-save', $remote_repository, $branch);
  $command->run('-m', $message, '--no-publish', $remote_repository, $branch);
  $command->run('-m', $message, '--no-deploy', $remote_repository, $branch);

all command executes the following git commands(giblog build, giblog save, giblog publish).

This is the same as the following command. In this example, the commit message is "Hello". the repository name is "origin". the branch name is "main".

  giblog build
  giblog save -m "Hello" origin main
  giblog publish origin main
  giblog deploy

If C<--no-build> option is specified, "giblog build" is not executed.

If C<--no-save> option is specified, "giblog save" is not executed.

If C<--no-publish> option is specified, "giblog publish" is not executed.

If C<--no-deploy> option is specified, "giblog deploy" is not executed.
