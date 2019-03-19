package Giblog;

use 5.008007;
use strict;
use warnings;

use Getopt::Long 'GetOptions';

our $VERSION = '0.51';

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, $class;
}

sub home_dir { shift->{'home_dir'} }
sub config { shift->{config} }

sub build_api {
  my ($class, %opt) = @_;
  
  my $giblog = Giblog->new(%opt);

  my $api = Giblog::API->new(giblog => $giblog);
  
  return $api;
}

sub parse_argv {
  my ($class, @argv) = @_;
  
  # If first argument don't start with -, it is command
  my $command_name;
  if (@argv && $argv[0] !~ /^-/) {
    $command_name = shift @argv;
  }

  # Command
  unless (defined $command_name) {
    die "Command must be specifed\n";
  }
  if ($command_name =~ /^-/) {
    die "Command \"$command_name\" is not found\n";
  }
  
  local @ARGV = @argv;
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
  GetOptions(
    "h|home=s" => \my $home_dir,
    'I|include=s'  => \my @include,
  );
  Getopt::Long::Configure($getopt_option_save);
  
  my $opt = {
    home_dir => $home_dir,
    include => \@include,
    command_name => $command_name,
    argv => \@argv
  };
  
  return $opt;
}

=head1 NAME

Giblog - HTML Generator

=head1 DESCRIPTION

Giblog is HTML generator.

Giblog is in beta test before 1.0 release. Note that features is changed without warnings.

=head1 SYNOPSYS
  
  # New web site
  giblog new mysite
  
  # Add new entry
  giblog add

  # Add new entry with option
  giblog add --home /my/home

  # Build web site
  giblog build
  
  # Build web site with option
  giblog build --home /my/home

=head1 TUTORIAL

=head2 Create web site

You can create web site from 4 prototype

=over 4

=item 1. Empty prototype

  giblog new mysite

If you want to create empty site, choice this prototype.

Templates and CSS is empty and provide basic build process.

=item 2. Home page prototype

  giblog new_hp mysite

If you want to create home page, choice this prototype.

Have empty "templates/index.html". CSS is designed to match smart phone site and provide basic build process.

=item 3. Blog prototype

  giblog new_blog mysite

Have page "templates/index.html" which show 7 days entry.

Have page "templates/list.html" which show all page links.

CSS is designed to match smart phone site and provide basic build process.

=head2 Add entry page

You can add entry page of blog by C<add> command.
  
  cd mysite
  giblog add mysite

For example, created file name is

  templates/blog/20080108132865.html

=head2 Build web site

You can build web site.

  giblog build

What is build process?

Build process is writen in "run" method of "lib/Giblog/Command/build.pm".

Main part of build process is combination of L<Giblog::API>.

  # This is create by new prototype
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

You can edit this build process by yourself if you need.

=head2 Serve web site

If you have L<Mojolicious>, you can build and serve web site.

   morbo serve.pl

You see the following message.

   Server available at http://127.0.0.1:3000
   Server start

If files in "templates" directory is updated, this server is automatically reloaded.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
