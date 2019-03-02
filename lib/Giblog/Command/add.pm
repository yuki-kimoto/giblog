package Giblog::Command::add;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self) = @_;
  
  my $api = $self->api;
  
  my $entry_dir = $api->rel_file('templates/blog');
  
  warn $entry_dir;
  
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
}

1;
