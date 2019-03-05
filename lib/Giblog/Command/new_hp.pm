package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, $website_name) = @_;

  my $api = $self->api;
  
  my $module_name = ref $self;
  
  my $proto_dir = $api->get_proto_dir($module_name);
  
  $api->create_website($website_name, $proto_dir);
}

1;
