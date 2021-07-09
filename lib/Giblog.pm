package Giblog;

use 5.008007;
use strict;
use warnings;

use Getopt::Long 'GetOptions';
use Giblog::API;
use Carp 'confess';
use Pod::Usage 'pod2usage';
use List::Util 'min';
use File::Spec;

our $VERSION = '1.02';

sub new {
  my $class = shift;

  my $self = {
    @_
  };

  return bless $self, $class;
}

sub _extract_usage {
  my $file = @_ ? "$_[0]" : (caller 1)[1];

  open my $handle, '>', \my $output;
  pod2usage -exitval => 'noexit', -input => $file, -output => $handle;
  $output =~ s/^.*\n|\n$//;
  $output =~ s/\n$//;

  return _unindent($output);
}

sub _unindent {
  my $str = shift;
  my $min = min map { m/^([ \t]*)/; length $1 || () } split "\n", $str;
  $str =~ s/^[ \t]{0,$min}//gm if $min;
  return $str;
}

sub run_command {
  my ($class, @argv) = @_;

  # Command line option
  local @ARGV = @argv;
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
  GetOptions(
    "h|help" => \my $help,
    "H|home=s" => \my $home_dir,
  );
  Getopt::Long::Configure($getopt_option_save);

  # Command name
  my $command_name = shift @ARGV;

  # Show help
  die _extract_usage if $help || !$command_name;

  # Giblog
  my $giblog = Giblog->new(home_dir => $home_dir);

  # API
  my $api = Giblog::API->new(giblog => $giblog);

  # Add "lib" in home directory to include path
  local @INC = @INC;
  if (defined $home_dir) {
    unshift @INC, "$home_dir/lib";
  }
  else {
    unshift @INC, "lib";
  }

  # Command is implemented in command
  my $command_class = "Giblog::Command::$command_name";
  eval "use $command_class;";
  if ($@) {
    confess "Can't load command $command_class:\n$!\n$@";
  }
  my $command = $command_class->new(api => $api);

  @argv = @ARGV;
  $command->run(@argv);
}

sub home_dir { shift->{'home_dir'} }
sub config { shift->{config} }

sub build {
  my ($class) = @_;

  # Build
  my $cmd = 'giblog build';
  system($cmd) == 0
    or die "Can't execute $cmd: $!";
}

sub serve {
  my ($class, $app) = @_;

  # Read config file
  my $config_file = "$FindBin::Bin/giblog.conf";
  my $config;
  $config = do $config_file
    or die "Can't read config file $config_file";

  # Remove base path before dispatch
  my $base_path = $config->{base_path};
  if (defined $base_path) {

    # Subdir depth
    my @parts = File::Spec->splitdir($base_path);
    my $subdir_depth = @parts - 1;

    $app->hook(before_dispatch => sub {
      my $c = shift;

      # Root is redirect
      unless (@{$c->req->url->path->parts}) {
        $c->stash(is_redirect => 1);
      }

      # Remove base path
      for (my $i = 0; $i < $subdir_depth; $i++) {
        shift @{$c->req->url->path->parts};
      }
    });
  }

  my $r = $app->routes;

  $r->get('/' => sub {
    my $c = shift;

    my $is_redirect = $c->stash('is_redirect');
    if ($is_redirect) {
      $c->redirect_to($base_path);
    }
    else {
      $c->reply->static('index.html');
    }
  });

  $app->start;
}

=encoding utf8

=head1 NAME

Giblog - Web site and Blog builders you can manage with Git

=begin html

<p>
  <b>Website</b>
</p>
<p>
  <a href="https://new-website-example.giblog.net/"><img src="https://github.com/yuki-kimoto/giblog/raw/master/images/giblog-website.png"></a>
</p>
<p>
  <a href="https://new-website-example.giblog.net/">Website Example</a>
</p>
<p>
  <b>Blog</b>
</p>
<p>
  <a href="https://new-blog-example.giblog.net/"><img src="https://github.com/yuki-kimoto/giblog/raw/master/images/giblog-blog.png"></a>
</p>
<p>
  <a href="https://new-blog-example.giblog.net/">Blog Example</a>
</p>

=end html

=head1 DESCRIPTION

Giblog is B<Website and Blog builder> written by Perl.
You can create B<your website and blog> easily.
All created files is B<static files>, so you can manage them using B<git>.
You can B<customize your website by Perl>.

=head1 SYNOPSYS

  # New empty web site
  giblog new mysite

  # New web site
  giblog new_website mysite

  # New blog
  giblog new_blog mysite

  # Change directory
  cd mysite

  # Add new entry
  giblog add

  # Build web site
  giblog build

  # Serve a web site
  giblog serve

  # Add new entry with home directory
  giblog add --home /home/kimoto/mysite

  # Build web site with home directory
  giblog build --home /home/kimoto/mysite

=head1 FEATURES

Giblog have the following features.

=over 4

=item * Build Website and Blog.

=item * Git mangement. All created files is Static. you can manage files by git.

=item * Linux, macOS, Windows Support. (In Windows, recommend installation of msys2)

=item * Provide default CSS for Smart phone site.

=item * Header, Hooter and Side bar support

=item * You can customize Top and Bottom section of content.

=item * You can customize HTML head.

=item * Automatical Line break. p tag is automatically added.

=item * Escape E<lt>, E<gt> automatically in pre tag

=item * Title tag is automatically added from first h1-h6 tag.

=item * Description meta tag is automatically added from first p tag.

=item * You can customize your web site by Perl.

=item * You can serve your web site in local environment. Contents changes is detected and build automatically(need L<Mojolicious>).

=item * Fast. Build 645 pages by 0.78 seconds in starndard linux environment.

=item * Support Github Pages, both user and project page.

=back

=head1 TUTORIAL

=head2 Create web site

B<1. Create Empty website>

"new" command create empty website. "mysite" is a name of your web site.

  giblog new mysite

If you want to create empty site, choice this command.
Templates and CSS is empty and provide minimal site building process.

B<2. Create Website>

"new_website" command create simple website.  "mysite" is a name of your web site.

  giblog new_website mysite

If you want to create simple website, choice this command.
Top page "templates/index.html" is created.
List page "templates/list.html" is created, which is prepare to create blog entry pages easily for feature.

CSS is responsive design and supports smart phone and provide basic site building process.

B<3. Create Blog>

"new_blog" command create empty website.  "mysite" is a name of your web site.

  giblog new_blog mysite

If you want to create blog, choice this prototype.
Top page "templates/index.html" is created, which show 7 days entries.
List page "templates/list.html" is created, which show all entries links.

CSS is responsive design and supports smart phone and provide basic blog building process.

=head2 Add blog entry page

You need to change directory to "mysite" before run "add" command if you are in other directory.

  cd mysite

"add" command add entry page.

  giblog add

Created file name is, for example,

  templates/blog/20080108132865.html

This file name contains current date and time.

To write new entry, You open it, write h2 head and content.

  <h2>How to use Giblog</h2>

  How to use Giblog. This is ...

Other parts wrapping content like Header and footer is automatically added in building process.

=head2 Add content page

If you want to create content page, put file into "templates" directory.

  templates/access.html
  templates/profile.html

Then open these file, write h2 head and content.

  <h2>How to use Giblog</h2>

  How to use Giblog. This is ...

Other parts wrapping content like Header and footer is automatically added in building process.

You can put file into sub directory.

  templates/profile/more.html

Note that "templates/static" and "templates/common" is special directories.
Don't push content page files into these directories.

  # Special directories you don't put content page files into
  templates/static
  templates/common

=head2 Add static page

If you want to add static files like css, images, JavaScript, You put these file into "templates/static" directory.

Files in "templates/static" directory is only copied to public files by build process.

  templates/static/js/jquery.js
  templates/static/images/logo.png
  templates/static/css/more.css

=head2 Customize header or footer, side bar, top of content, bottom of content

You can customize header, footer, side bar, top of content, bottom of content.

  ------------------------
  Header
  ------------------------
  Top of content   |
  -----------------|
                   |Side
  Content          |bar
                   |
  -----------------|
  Bottom of content|
  ------------------------
  Footer
  ------------------------

If you want to edit these section, you edit these files.

  templates/common/header.html     Header
  templates/common/top.html        Top of content
  templates/common/side.html       Side bar
  templates/common/bottom.html     Bottom of content
  templates/common/footer.html     Footer

=head2 Customize HTML header

You can customize HTML header.

  <html>
    <head>
      <!-- HTML header -->
    </head>
    <body>

    </body>
  </html>

If you want to edit HTML header, you edit the following file.

  templates/common/meta.html

=head2 Build web site

You need to change directory to "mysite" before run "build" command if you are in other directory.

  cd mysite

"build" command build web site.

  giblog build

What is build process?

build process is writen in "lib/Giblog/Command/build.pm".

"build" command only execute "run" method in "Giblog::Command::build.pm" .

  # "lib/Giblog/Command/build.pm" in web site created by "new_blog" command
  package Giblog::Command::build;

  use base 'Giblog::Command';

  use strict;
  use warnings;

  use File::Basename 'basename';

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
      # Data
      my $data = {file => $file};

      # Get content from file in templates directory
      $api->get_content($data);

      # Parse Giblog syntax
      $api->parse_giblog_syntax($data);

      # Parse title
      $api->parse_title_from_first_h_tag($data);

      # Edit title
      my $site_title = $config->{site_title};
      if ($data->{file} eq 'index.html') {
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

      # Write to public file
      $api->write_to_public_file($data);
    }

    # Create index page
    $self->create_index;

    # Create list page
    $self->create_list;
  }

You can customize build process if you need.

If you need to know Giblog API, see L<Giblog::API>.

=head2 Serve web site

You can serve web site by C<serve> command.

   # Serve web site
   giblog serve

You see the following message.

   Web application available at http://127.0.0.1:3000

This command is same as the following code. L<morbo> command of L<Mojolicious> start up C<serve.pl>.

   # Same as the following
   morbo -w giblog.conf -w lib -w templates serve.pl

If C<giblog.conf>, files in C<templates> or C<lib> directory is changed, Web site is automatically rebuild.

If you use before Giblog 2.0, you can serve a web site by the following way.

   # Old style before Giblog 2.0
   morbo serve.pl

=head2 Publish web site

You can publish the web site by C<publish> command.

   # Publish the web site
   giblog publish origin main

This command is same as the following.

  git -C public add .
  git -C public commit -m "Published at YY-mm-dd HH:MM:SS"
  git -C public push origin main

=head1 CONFIG FILE

Giblog config file is "giblog.conf".

This is Perl script and return config as hash reference.

  use strict;
  use warnings;
  use utf8;

  # giblog.conf
  {
    site_title => 'mysite😄',
    site_url => 'http://somesite.example',
  }

=head2 site_title

  site_title => 'mysite😄'

Site title

=head2 site_url

  site_url => 'http://somesite.example'

Site URL.

=head2 base_path

  base_path => '/subdir'

Base path. Base path is used to deploy your site to sub directory.

For example, Project page URL of Github Pages is

  https://yuki-kimoto.github.io/giblog-theme1-public/

You specify the following

  base_path => '/giblog-theme1-public'

Top character of base_path must be slash "/".

HTML files is output into "public/giblog-theme1-public" directory.

=head1 METHODS

These methods is internally methods.
Normally, you don't need to know these methods.
See L<Giblog::API> to manipulate HTML contents.

=head2 new

  my $api = Giblog->new(%params);

Create L<Giblog> object.

B<Parameters:>

=over 4

=item * home_dir - home directory

=item * config - config

=back

=head2 run_command

  $giblog->run_command(@argv);

Run command system.

=head2 config

  my $config = $giblog->config;

Get Giblog config.

=head2 home_dir

  my $home_dir = $giblog->home_dir;

Get home directory.

=head1 FAQ

=head2 Dose Giblog support Windows?

Giblog does'nt support Native Windows(Strawberry Perl, or Active Perl) because Giblog depends on Git and Mojolicious.

If you use Giblog in Windows, you can use WSL2.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 CONTRIBUTORS

Yasuaki Omokawa, C<< <omokawa at senk-inc.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
