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
    $api->add_page_link($data, {root => 'index.html'});

    # Parse description
    $api->parse_description($data);

    # Create description from first p tag
    $api->parse_description_from_first_p_tag($data);

    # Parse keywords
    $api->parse_keywords($data);

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Add meta description
    $api->add_meta_description($data);

    # Wrap content by header, footer, etc
    $api->wrap($data);
  });
}

1;
