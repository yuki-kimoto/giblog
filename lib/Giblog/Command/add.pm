package Giblog::Command::add;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self) = @_;
  
  my $api = $self->api;
  
  my $entry_dir = $api->rel_file('templates/blog');
  
  # Data and time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  $year += 1900;
  $mon++;
  my $datetime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  
  my $entry_file = "$entry_dir/$datetime.html";
  my $entry = <<"EOS";
<!-- /blog/$datetime -->

EOS
  $api->write_to_file($entry_file, $entry);
  
  warn "Create $entry_file\n";
}

1;

=head1 NAME

Giblog::Command::add - add command

=head1 METHODS

L<Giblog::Command::add> inherits all methods from L<Giblog::Command> and
implements the following add ones.

=head2 run

  $command->run(@argv);

Execute add command.
