package Giblog::Command::build;

use base 'Giblog::Command::base_build';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  # Write pre process
  
  $self->SUPER::run(@args);
  
  # Write post porsess
}

1;
