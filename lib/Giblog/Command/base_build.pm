package Giblog::Command::base_build;

use base 'Giblog::Command';

use strict;
use warnings;
use File::Find 'find';
use Carp 'confess';
use File::Basename 'dirname';
use File::Path 'mkpath';
use Encode 'encode', 'decode';
use Giblog::Util;

sub run {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  $giblog->read_config;
  
  $self->build;
}

sub build {
  my ($self) = @_;
  
  my $giblog = $self->giblog;

  my $templates_dir = $giblog->rel_file('templates');
  my $public_dir = $giblog->rel_file('public');
  
  # Get template files
  my @template_rel_files;
  find(
    {
      wanted => sub {
        my $template_file = $File::Find::name;
        
        # Skip directory
        return unless -f $template_file;

        # Skip common files
        return if $template_file =~ /^\Q$templates_dir\/common/;
        
        my $template_file_base = $_;
        
        # Skip hidden file
        return if $template_file_base =~ /^\./;
        
        my $template_rel_file = $template_file;
        $template_rel_file =~ s/^$templates_dir//;
        $template_rel_file =~ s/^[\\\/]//;
        $template_rel_file = "templates/$template_rel_file";
        
        push @template_rel_files, $template_rel_file;
      },
      no_chdir => 1,
    },
    $templates_dir
  );
  
  for my $template_rel_file (@template_rel_files) {
    my $template_file = $giblog->rel_file($template_rel_file);
    my $content = $giblog->slurp_file($template_file);
    
    my $path = $template_rel_file;
    $path =~ s|^templates||;
    if ($path eq '/index.html') {
      $path = '/';
    }
    
    my $data = {
      content => $content,
      path => $path,
    };

    # Build html
    $self->build_html($data);
    
    my $html = $data->{content};
    
    # public file
    my $public_rel_file = $template_rel_file;
    $public_rel_file =~ s/^templates/public/;
    my $public_file = $giblog->rel_file("$public_rel_file");
    my $public_dir = dirname $public_file;
    mkpath $public_dir;
    
    # Write to public file
    $giblog->write_to_file($public_file, $html);
  }
}

sub build_html {
  my ($self, $data) = @_;
  
  # Nothing
}

1;
