package Giblog::Command::add;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self) = @_;
  
  my $giblog = $self->giblog;
  
  my $entry_dir = $giblog->rel_file('templates/blog');
  
  # Data and time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  $year += 1900;
  $mon++;
  my $datetime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  
  my $entry_file = "$entry_dir/$datetime.html";
  my $entry = <<"EOS";
<!-- /blog/$datetime -->

EOS
  $giblog->write_to_file($entry_file, $entry);
}

1;
