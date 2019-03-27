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
  
  # Copy static files to public
  $api->copy_static_files_to_public;
  
  # Get files in templates directory
  my $files = $api->get_templates_files;
  
  for my $file (@$files) {
    
    # CGI
    if ($file =~ /\.cgi$/) {
      
      # CGI content
      my $cgi_content;
      {
        # Data
        my $data = {file => $file};

        # Get content from file in templates directory
        $api->get_content($data);
        
        # CGI content
        $cgi_content = $data->{content};
      }
      
      # Data
      my $data = {file => $file};
      
      # Read common templates
      $api->read_common_templates($data);
      
      # Title(Replaced by CGI)
      $data->{title} = '$TITLE';
      
      # Add meta title
      $api->add_meta_title($data);
      
      # Content(Replaced by CGI)
      $data->{content} = '$CONTENT';
      
      # Build entry html
      $api->build_entry($data);
      
      # Build whole html
      $api->build_html($data);
      
      # Add html to CGI DATA section
      $data->{content} = "$cgi_content\n$data->{content}";
      
      # Write to public file
      $api->write_to_public_file($data);
      
      # Do executable
      chmod 0755, $api->rel_file("public/$file");
    }
    # HTML, etc
    else {
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
}

1;
