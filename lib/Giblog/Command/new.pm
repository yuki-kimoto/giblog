package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

use Carp 'confess';

use File::Path 'mkpath';
use File::Copy 'copy';
use File::Basename 'dirname';
use File::Find 'find';

sub run {
  my ($self, $website_name) = @_;
  
  my $api = $self->api;
  
  unless (defined $website_name) {
    die "Website name must be specifed\n";
  }
  if ($website_name !~ /^[a-zA-Z0-9_\-]+$/) {
    die "Website name \"$website_name\" is invalid\n";
  }
  
  if (-f $website_name) {
    die "Website \"$website_name\" is already exists\n";
  }
  
  my $command_class = ref $self;
  my $command_proto_dir = $api->command_rel_file($self, 'proto');

  # Create website directory
  $api->create_dir($website_name);

  # Copy command proto files to user directory
  my @files;
  find(
    {
      wanted => sub {
        my $command_proto_file = $File::Find::name;
        
        # Skip directory
        return unless -f $command_proto_file;
        
        my $rel_file = $command_proto_file;
        $rel_file =~ s/^\Q$command_proto_dir\E[\/|\\]//;
        
        my $user_file = "$website_name/$rel_file";
        my $user_dir = dirname $user_file;
        mkpath $user_dir;
        
        copy $command_proto_file, $user_file
          or confess "Can't copy $command_proto_file to $user_file: $!";
      },
      no_chdir => 1,
    },
    $command_proto_dir
  );
  
  # Create giblog.conf
  my $config_file = "$website_name/giblog.conf";
  unless (-f $config_file) {
    $api->create_file($config_file);
    my $config = <<"EOS";
{
  site_title => 'Web Site Name',
  site_url => 'http://somesite.example',
}
EOS
    $api->write_to_file($config_file, $config);
  }
  
  # Create web application
  my $webapp_file = "$website_name/serve.pl";
  unless (-f $webapp_file) {
    $api->create_file($webapp_file);
    my $webapp = <<'EOS';
use strict;
use warnings;

my $cmd = 'giblog build';
system($cmd) == 0
  or die "Can't execute $cmd: $!";

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
EOS
    $api->write_to_file($webapp_file, $webapp);
  }
  
  # Create build command
  mkpath "$website_name/lib/Giblog/Command";
  my $build_command_file = "$website_name/lib/Giblog/Command/build.pm";
  unless (-f $build_command_file) {
    $api->create_file($build_command_file);
    my $build_command = <<'EOS';
package Giblog::Command::build;

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

    # Parse description
    $api->parse_description($data);

    # Create description from first p tag
    $api->parse_description_from_first_p_tag($data);

    # Parse keywords
    $api->parse_keywords($data);

    # Parse first image src
    $api->parse_first_img_src($data);

    # Prepare wrap content
    $api->prepare_wrap_content($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Add meta description
    $api->add_meta_description($data);

    # Wrap content by header, footer, etc
    $api->wrap_content($data);
  });
}

1;
EOS
    $api->write_to_file($build_command_file, $build_command);
  }
}

1;
