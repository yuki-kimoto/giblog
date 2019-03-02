package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  my $api = $self->api;
  
  $api->read_config;
  
  $api->build_all(sub {
    my ($api, $data) = @_;
    
    # Config
    my $config = $api->config;

    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Parse title
    $api->parse_title($data);

    # Add page link
    $api->add_page_link($data);

    # Prepare wrap content
    $api->prepare_wrap_content($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Wrap content by header, footer, etc
    $api->wrap_content($data);
  });
}

1;
