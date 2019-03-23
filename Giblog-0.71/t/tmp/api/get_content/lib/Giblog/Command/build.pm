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
    $api->parse_title_from_first_h_tag($data);

    # Add page link
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);
    
    # Build entry html
    $api->build_entry($data);
    
    # Build whole html
    $api->build_html($data);
    
    # Write to public file
    $api->write_to_public_file($data);
  }
}

1;
