package Giblog::Plugin::build;

use base 'Giblog::Plugin';

use strict;
use warnings;
use File::Find 'find';

sub plugin {
  my ($self, $giblog) = @_;

  my $templates_dir = $giblog->rel_file('templates');
  my $public_dir = $giblog->rel_file('public');
  
  # Get template files
  my @template_files;
  find(
    {
      wanted => sub {
        my $template_file = $File::Find::name;
        
        # Skip directory
        return unless -f $template_file;
        
        push @template_files, $template_file;
      },
      no_chdir => 1,
    },
    $templates_dir
  );
  
  for my $template_file (@template_files) {
    $giblog->build_public_file($templates_dir, $template_file);
  }
}

1;
