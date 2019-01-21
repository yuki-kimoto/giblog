package Giblog::Plugin::new;

use strict;
use warnings;


sub plugin {
  my ($self, $giblog, $website_name) = @_;
  
  unless (defined $website_name) {
    die "Website name must be specifed\n";
  }
  if ($website_name !~ /^[a-zA-Z0-9_\-]+$/) {
    die "Website name \"$website_name\" is invalid\n";
  }
  
  if (-f $website_name) {
    die "Website \"$website_name\" is already exists\n";
  }
  
  my $website_dir = $giblog->rel_file($website_name);
  
  # Create website directory
  $giblog->create_dir($website_name);
  
  # Create giblog.conf
  my $config_file = "$website_name/giblog.conf";
  $giblog->create_file($config_file);
  my $config = $giblog->config($website_name);
  $giblog->write_to_file($config_file, $config);
  
  # Create public directory
  my $public_dir = "$website_name/public";
  $giblog->create_dir($public_dir);

  # Create public/blog directory
  my $public_blog_dir = "$website_name/public/blog";
  $giblog->create_dir($public_blog_dir);

  # Create public/blog/.gitkeep file
  my $public_blog_gitkeep_file = "$website_name/public/blog/.gitkeep";
  $giblog->create_file($public_blog_gitkeep_file);

  # Create public/css directory
  my $public_css_dir = "$public_dir/css";
  $giblog->create_dir($public_css_dir);

  # Create public/common.css file
  my $public_css_common_file = "$public_css_dir/common.css";
  $giblog->create_file($public_css_common_file);
  my $templates_common_css = $giblog->common_css;
  $giblog->write_to_file($public_css_common_file, $templates_common_css);

  # Create public/images directory
  my $public_images_dir = "$public_dir/images";
  $giblog->create_dir($public_images_dir);

  # Create public/images/.gitkeep file
  my $public_images_gitkeep_file = "$website_name/public/images/.gitkeep";
  $giblog->create_file($public_images_gitkeep_file);

  # Create public/js directory
  my $public_js_dir = "$public_dir/js";
  $giblog->create_dir($public_js_dir);

  # Create public/js/.gitkeep file
  my $public_js_gitkeep_file = "$website_name/public/js/.gitkeep";
  $giblog->create_file($public_js_gitkeep_file);

  # Create templates directory
  my $templates_dir = "$website_name/templates";
  $giblog->create_dir($templates_dir);

  # Create templates/index.html file
  my $templates_index_file = "$templates_dir/index.tmpl.html";
  my $templates_index = <<"EOS";
aiueo

<!-- index -->
  <div>
    ppp
  </div>
aiueo

EOS
  $giblog->write_to_file($templates_index_file, $templates_index);

  # Create templates/blog directory
  my $templates_blog_dir = "$website_name/templates/blog";
  $giblog->create_dir($templates_blog_dir);

  # Create templates/blog/.gitkeep file
  my $templates_blog_gitkeep_file = "$templates_blog_dir/.gitkeep";
  $giblog->create_file($templates_blog_gitkeep_file);

  # Create common directory
  my $templates_common_dir = "$website_name/common";
  $giblog->create_dir($templates_common_dir);

  # Create common/meta.tmpl.html file
  my $templates_common_meta_file = "$templates_common_dir/meta.tmpl.html";
  $giblog->create_file($templates_common_meta_file);
  my $templates_common_meta = $giblog->common_meta;
  $giblog->write_to_file($templates_common_meta_file, $templates_common_meta);
  
  # Create common/header.tmpl.html file
  my $templates_common_header_file = "$templates_common_dir/header.tmpl.html";
  $giblog->create_file($templates_common_header_file);
  my $templates_common_header = $giblog->common_header;
  $giblog->write_to_file($templates_common_header_file, $templates_common_header);

  # Create common/side.tmpl.html file
  my $templates_common_side_file = "$templates_common_dir/side.tmpl.html";
  $giblog->create_file($templates_common_side_file);
  my $templates_common_side = $giblog->common_side;
  $giblog->write_to_file($templates_common_side_file, $templates_common_side);
  
  # Create common/footer-top.tmpl.html file
  my $templates_common_footer_file = "$templates_common_dir/footer.tmpl.html";
  $giblog->create_file($templates_common_footer_file);
  my $templates_common_footer = $giblog->common_footer;
  $giblog->write_to_file($templates_common_footer_file, $templates_common_footer);
  
  # Create common/entry-top.tmpl.html file
  my $templates_common_entry_top_file = "$templates_common_dir/entry-top.tmpl.html";
  $giblog->create_file($templates_common_entry_top_file);
  my $templates_common_entry_top = $giblog->common_entry_top;
  $giblog->write_to_file($templates_common_entry_top_file, $templates_common_entry_top);
  
  # Create common/entry-bottom.tmpl.html file
  my $templates_common_entry_bottom_file = "$templates_common_dir/entry-bottom.tmpl.html";
  $giblog->create_file($templates_common_entry_bottom_file);
  my $templates_common_entry_bottom = $giblog->common_entry_bottom;
  $giblog->write_to_file($templates_common_entry_bottom_file, $templates_common_entry_bottom);
}

1;
