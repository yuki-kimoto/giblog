package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  # API
  my $api = $self->api;
  
  # Read config
  my $config = $api->read_config;
  
  # Get files in templates directory
  my $files = $api->get_templates_files;
  
  for my $file (@$files) {
    
    my $data = {file => $file};
    
    # Get content from file in templates directory
    $api->get_content($data);

    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Parse title
    $api->parse_title($data);

    # Add page link
    $api->add_page_link($data, {root => 'index.html'});

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Wrap content by header, footer, etc
    $api->wrap($data);
    
    # Write to public file
    $api->write_to_public_file($data);
  }
}

1;
