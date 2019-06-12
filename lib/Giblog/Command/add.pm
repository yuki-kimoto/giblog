package Giblog::Command::add;

use base 'Giblog::Command';

use strict;
use warnings;
use Carp 'confess';

sub run {
  my ($self) = @_;
  
  my $api = $self->api;
  
  my $entry_dir = $api->rel_file('templates/blog');
  
  # Data and time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  $year += 1900;
  $mon++;
  my $datetime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  
  # Create entry file
  my $entry_file = "$entry_dir/$datetime.html";
  if (-f $entry_file) {
    confess "Fail add command. $entry_file is Alread exists";
  }
  $api->create_file($entry_file);
  
  warn "Create $entry_file\n";
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::add - new blog entry adding command

=head1 DESCRIPTION

L<Giblog::Command::add> is new blog entry adding command.

=head1 METHODS

L<Giblog::Command::add> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run;

Create a new blog entry page file in "templates/blog" directory.

The file contains date and time.

  templates/blog/20190416153053.html
