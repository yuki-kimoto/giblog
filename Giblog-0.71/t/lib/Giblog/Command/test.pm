package Giblog::Command::test;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  my $num_ref = $args[0];
  
  $$num_ref = 3;
}

1;
