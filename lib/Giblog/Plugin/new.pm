package Giblog::Plugin::new;

use base 'Giblog::Plugin';

use strict;
use warnings;

use Carp 'confess';

use File::Path 'mkpath';
use File::Copy 'copy';
use File::Basename 'dirname';
use File::Find 'find';

sub plugin {
  my ($self, $website_name) = @_;
  
  my $giblog = $self->giblog;
  
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
  
  my $plugin_class = ref $self;
  my $plugin_templates_dir = $giblog->plugin_rel_file($self, 'templates');
  my $plugin_common_dir = $giblog->plugin_rel_file($self, 'common');
  my $plugin_public_dir = $giblog->plugin_rel_file($self, 'public');

  # Create website directory
  $giblog->create_dir($website_name);
  
  # Create giblog.conf
  my $config_file = "$website_name/giblog.conf";
  $giblog->create_file($config_file);
  my $config = <<"EOS";
{
  site_title => "$website_name",
  proto => "$plugin_class",
}
EOS
  $giblog->write_to_file($config_file, $config);
  
  # Create public directory
  my $user_public_dir = "$website_name/public";
  $giblog->create_dir($user_public_dir);

  # Create templates directory
  my $user_templates_dir = "$website_name/templates";
  $giblog->create_dir($user_templates_dir);

  # Copy plugin templates files to user templates file
  my @template_files;
  find(
    {
      wanted => sub {
        my $plugin_template_file = $File::Find::name;
        
        # Skip directory
        return unless -f $plugin_template_file;
        
        my $template_rel_file = $plugin_template_file;
        $template_rel_file =~ s/^\Q$plugin_templates_dir\E[\/|\\]//;
        
        my $user_template_file = "$user_templates_dir/$template_rel_file";
        my $user_templates_dir = dirname $user_template_file;
        mkpath $user_templates_dir;
        
        copy $plugin_template_file, $user_template_file
          or confess "Can't copy $plugin_template_file to $user_template_file: $!";
      },
      no_chdir => 1,
    },
    $plugin_templates_dir
  );

  # Copy plugin publics files to user publics file
  my @public_files;
  find(
    {
      wanted => sub {
        my $plugin_public_file = $File::Find::name;
        
        # Skip directory
        return unless -f $plugin_public_file;
        
        my $public_rel_file = $plugin_public_file;
        $public_rel_file =~ s/^\Q$plugin_public_dir\E[\/|\\]//;
        
        my $user_public_file = "$user_public_dir/$public_rel_file";
        my $user_public_dir = dirname $user_public_file;
        mkpath $user_public_dir;
        
        copy $plugin_public_file, $user_public_file
          or confess "Can't copy $plugin_public_file to $user_public_file: $!";
      },
      no_chdir => 1,
    },
    $plugin_public_dir
  );
}

1;
