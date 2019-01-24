package Giblog::Plugin::build;

use base 'Giblog::Plugin::base_build';

use strict;
use warnings;

sub plugin {
  my ($self, @args) = @_;
  
  # Write pre process
  
  $self->SUPER::plugin(@args);
  
  # Write post porsess
}

1;
