package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;
use utf8;

use File::Basename 'basename';

sub run {
  my ($self, @args) = @_;
  
  # API
  my $api = $self->api;
  
  # Read config
  my $config = $api->read_config;
  
  # Copy static files to public
  $api->copy_static_files_to_public;
  
  # Add base path to public css files
  $api->add_base_path_to_public_css_files;
  
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

    # Edit title
    my $site_title = $config->{site_title};
    if ($data->{file} eq 'index.html' || !defined $data->{title}) {
      $data->{title} = $site_title;
    }
    else {
      $data->{title} = "$data->{title} - $site_title";
    }

    # Add page link
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});

    # Parse description
    $api->parse_description_from_first_p_tag($data);

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Add meta description
    $api->add_meta_description($data);

    # Build entry html
    $api->build_entry($data);
    
    # Build whole html
    $api->build_html($data);
    
    # Add base path to content
    $api->add_base_path_to_content($data);
    
    # Write to public file
    $api->write_to_public_file($data);
  }

  # Create list page
  $self->create_list;
}

# Create all entry list page
sub create_list {
  my $self = shift;
  
  # API
  my $api = $self->api;
  
  # Config
  my $config = $api->config;
  
  # Template files
  my @template_files = glob $api->rel_file('templates/blog/*');
  @template_files = reverse sort @template_files;

  # Data
  my $data = {file => 'list.html'};
  
  # Entries
  {
    my $content;
    $content = <<'EOS';
<h2>Entries</h2>
EOS
    $content .= "<ul>\n";
    my $before_year = 0;
    for my $template_file (@template_files) {
      # Day
      my $base_name = basename $template_file;
      my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
      $month =~ s/^0//;
      $mday =~ s/^0//;
      
      # Year
      if ($year != $before_year) {
        $content .= <<"EOS";
  <li style="list-style:none;">
    <b>${year}</b>
  </li>
EOS
      }
      $before_year = $year;
      
      # File
      my $file_entry = "blog/$base_name";
      
      # Data
      my $data_entry = {file => $file_entry};
      
      # Get content
      $api->get_content($data_entry);
      
      # Parse title from first h tag
      $api->parse_title_from_first_h_tag($data_entry);
      
      # Title
      my $title = $data_entry->{title};
      unless(defined $title) {
        $title = 'No title';
      }
      
      # Add list
      $content .= <<"EOS";
  <li style="list-style:none">
    $month/$mday <a href="/$file_entry">$title</a>
  </li>
EOS
    }
    $content .= "</ul>\n";
    
    # Set content
    $data->{content} = $content;
  }
  
  # Add page link
  $api->add_page_link_to_first_h_tag($data);

  # Title
  $data->{title} = "Entries - $config->{site_title}";
  
  # Description
  $data->{description} = "Entries of $config->{site_title}";

  # Read common templates
  $api->read_common_templates($data);

  # Add meta title
  $api->add_meta_title($data);

  # Add meta description
  $api->add_meta_description($data);

  # Build entry html
  $api->build_entry($data);
  
  # Build whole html
  $api->build_html($data);

  # Add base path to content
  $api->add_base_path_to_content($data);
  
  # Write content to public file
  my $public_file = $api->rel_file('public/list.html');
  $api->write_to_file($public_file, $data->{content});
}

1;
