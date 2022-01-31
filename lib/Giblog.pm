package Giblog;

use strict;
use warnings;

use Getopt::Long 'GetOptions';
use Giblog::API;
use Carp 'confess';
use Pod::Usage 'pod2usage';
use List::Util 'min';
use File::Spec;

our $VERSION = '3.00';

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
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case pass_through));
  GetOptions(
    "h|help" => \my $help,
    "H|C|home=s" => \my $home_dir,
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

Giblog - Create Websites and Blogs that can be managed with Git

=begin html

<p>
  <b>Website</b>
</p>
<p>
  <a href="https://new-website-example.giblog.net/"><img src="https://github.com/yuki-kimoto/giblog/raw/master/images/giblog-website.png"></a>
</p>
<p>
  <a href="https://new-website-example.giblog.net/">A Website Example</a>
</p>
<p>
  <b>Blog</b>
</p>
<p>
  <a href="https://new-blog-example.giblog.net/"><img src="https://github.com/yuki-kimoto/giblog/raw/master/images/giblog-blog.png"></a>
</p>
<p>
  <a href="https://new-blog-example.giblog.net/">A Blog Example</a>
</p>

=end html

=head1 DESCRIPTION

Giblog is a utility to create websites or blogs.
You can create websites or blogs using C<giblog> command.
All created files is static files. You can manage them using B<git>.
You can customize websites using C<Perl>.

=head1 SYNOPSYS
  
  # New empty website
  $ giblog new mysite

  # New website
  $ giblog new_website mysite

  # New blog
  $ giblog new_blog mysite

  # Change directory
  $ cd mysite

  # Add new entry
  $ giblog add

  # Add new entry with home directory
  $ giblog add -C /home/perlclub/mysite

  # Build website
  $ giblog build
  
  # Build website with home directory
  $ giblog build -C /home/perlclub/mysite

  # Serve a website
  $ giblog serve

  # Save a website
  $ giblog save -m "Commit Messages" origin main

  # Publish website
  $ giblog publish origin main

  # Deploy a website
  $ giblog deploy
  
  # Do "giblog build", "giblog save", "giblog publish", "giblog deploy" at once
  $ giblog all -m "Commit Messages" origin main

=head1 FEATURES

Giblog have the following features.

=over 4

=item * Build websites and blogs.

=item * All created files is static files. You can manage files using git.

=item * Linux, macOS, Windows Support. (Windows needs msys2 or WSL2)

=item * CSS supports smart phone.

=item * Header, hooter and side bar support

=item * Customize top and bottom section of content.

=item * Customize HTML head.

=item * Automatical Line break. p tag is automatically added.

=item * Escape E<lt>, E<gt> automatically in pre tag

=item * Title tag is automatically added from first h1-h6 tag.

=item * Description meta tag is automatically added from first p tag.

=item * You can customize your website by Perl.

=item * You can serve your website in local environment. Contents changes is detected and build automatically(need L<Mojolicious>).

=item * Fast. Build 645 pages by 0.78 seconds in starndard linux environment.

=item * Support Github Pages, both user and project page.

=back

=head1 TUTORIAL

=head2 Create Websites

=head3 Create a Empty website

L<giblog new|Giblog::Command::new> command create empty website. "mysite" is a name of your website.

  giblog new mysite

If you want to create empty site, choice this command.
Templates and CSS is empty and provide minimal site building process.

=head3 Create a Website

L<giblog new_website|Giblog::Command::new_website> command create simple website.  "mysite" is a name of your website.

  giblog new_website mysite

If you want to create simple website, choice this command.
Top page "templates/index.html" is created.
List page "templates/list.html" is created, which is prepare to create blog entry pages easily for feature.

CSS is responsive design and supports smart phone and provide basic site building process.

=head3 Create a Blog

L<giblog new_blog|Giblog::Command::new_blog> command create empty website.  "mysite" is a name of your website.

  giblog new_blog mysite

If you want to create blog, choice this prototype.
Top page "templates/index.html" is created, which show 7 days entries.
List page "templates/list.html" is created, which show all entries links.

CSS is responsive design and supports smart phone and provide basic blog building process.

=head2 Add a Blog Page

L<giblog add|Giblog::Command::add> command add entry page.

  giblog add

You need to change the directory created by L<giblog new|Giblog::Command::new>, L<giblog new_website|Giblog::Command::new_website>, or L<giblog new_blog|Giblog::Command::new_blog> before

Created file name is, for example,

  templates/blog/20080108132865.html

This file name contains current date and time.

To write new entry, You open it, write h2 head and content.

  <h2>How to use Giblog</h2>

  How to use Giblog. This is ...

Other parts wrapping content like Header and footer is automatically added in building process.

=head2 Add a Content Page

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

=head2 Add Satic files

If you want to add static files like css, images, JavaScript, You put these file into "templates/static" directory.

Files in "templates/static" directory is only copied to public files by build process.

  templates/static/js/jquery.js
  templates/static/images/logo.png
  templates/static/css/more.css

=head2 Customize Header or Footer, Side bar, Top of Content, Bottom of Content

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

=head2 Customize HTML Header

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

=head2 Giblog Variables

Explains Giblog variables.

=head3 Define Giblog Variables

You can define Giblog variable in C<giblog.conf>.

  # giblog.conf
  use strict;
  use warnings;
  use utf8;

  {
    site_title => 'mysite',
    site_url => 'http://somesite.example',
    
    # Variables
    vars => {
      giblog_test_variable => 'Giblog Test Variable',
    },
  }

C<vars> defines Giblog variables in C<giblog.conf>.

=head3 Use Giblog Variables

Use Giblog variables in templtes files.

  <%= $GIBLOG_VARIABLE_NAME %>

B<Examples:>

C<giblog.conf>

  # giblog.conf
  use strict;
  use warnings;
  use utf8;

  {
    site_title => 'mysite',
    site_url => 'http://somesite.example',
    
    # Variables
    vars => {
      giblog_test_variable => 'Giblog Test Variable',
      google_analytics_id => 'G-EIFHDUGHF45',
    },
  }

C<templates/common/meta.html>
 
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0">
  <link rel="shortcut icon" href="/images/logo.png">

  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=<%= $google_analytics_id %>"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', '<%= $google_analytics_id %>');
  </script>

=head2 Build a Website

Build a website using L<giblog build|Giblog::Command::build> command.

  giblog build

You need to change the directory created by L<giblog new|Giblog::Command::new>, L<giblog new_website|Giblog::Command::new_website>, or L<giblog new_blog|Giblog::Command::new_blog> before executing "giblog build" command.

L<giblog build|Giblog::Command::build> command execute C<run> method of C<Giblog::Command::build> module.

C<Giblog::Command::build> module exists in C<lib/Giblog/Command/build.pm>.

C<Giblog::Command::build> module is automatically created.

See C<Giblog::Command::build> module.

  # "lib/Giblog/Command/build.pm" in website created by "new_blog" command
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

    # Add base path to public css files
    $api->add_base_path_to_public_css_files;

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

      # Replace Giblog variables
      $api->replace_vars($data);
      
      # Add base path to content
      $api->add_base_path_to_content($data);

      # Write to public file
      $api->write_to_public_file($data);
    }

    # Create index page
    $self->create_index;

    # Create list page
    $self->create_list;
  }

You can customize build process using L<Giblog::API> and any Perl programs.

L<Giblog::API> is a usuful APIs to customize websites.

=head2 Serve a Website

You can serve a website by L<giblog serve|Giblog::Command::serve> command.

   # Serve website
   giblog serve

You see the following message.

   Web application available at http://127.0.0.1:3000

L<giblog serve|Giblog::Command::serve> means the following command. L<morbo> is a command to serve a L<Mojolicious> app in development mode.

   # Same as the following
   morbo -w giblog.conf -w lib -w templates serve.pl

If C<giblog.conf>, files in C<templates> or C<lib> directories are changed, the website is automatically rebuild.

B<Giblog 1.0:>

If you use Giblog 1, you can serve your website by the following way.

   # Giblog 1.0
   morbo -w giblog.conf -w lib -w templates serve.pl

=head2 Save a Website

Save Websites using L<giblog save|Giblog::Command::save>.

  giblog save -m "Commit Messages" origin main

L<giblog save|Giblog::Command::save> means the following git commands.

  git add --all
  git commit -m "Commit Messages"
  git push origin main

=head2 Publish a Website

Publish the website using L<giblog publish|Giblog::Command::publish> command.

   # Publish the website
   giblog publish origin main

This is the same as the following command. In this example, the repository name is origin and the branch name is main. YY-mm-dd HH:MM:SS is current date and time.

  git -C public add --all
  git -C public commit -m "Published by Giblog at YY-mm-dd HH:MM:SS"
  git -C public push -f origin main

=head2 Deploy a Website

Deploy websites using L<giblog deploy|Giblog::Command::deploy>.
  
  # Deploy websites
  giblog deploy

L<giblog save|Giblog::Command::save> means the following command.

  perl deploy.pl

You can write any program for the deployment in C<deploy.pl>.

  use strict;
  use warnings;

  my @args = @ARGV;

  my $deploy_cmd = q(ssh prod_perl_club_sites 'git -C ~/www/en_perlzemi-public fetch && git -C ~/www/en_perlzemi-public reset --hard origin/main');

  system($deploy_cmd) == 0
    or die "Can't execute deploy command: $deploy_cmd:$!";

=head2 Execute All Commands at Once

Do all Publish the website using L<giblog build|Giblog::Command::build>, L<giblog save|Giblog::Command::save>, L<giblog publish|Giblog::Command::publish>, L<giblog deploy|Giblog::Command::deploy> command.

  giblog all -m "Commit Messages" origin main

This means the following commands

  giblog build
  giblog save -m "Hello" origin main
  giblog publish origin main
  giblog deploy

If C<--no-build> option is specified, "giblog build" is not executed.

  giblog all --no-build -m "Commit Messages" origin main

If C<--no-save> option is specified, "giblog save" is not executed.

  giblog all --no-save -m "Commit Messages" origin main

If C<--no-publish> option is specified, "giblog publish" is not executed.

  giblog all --no-publish -m "Commit Messages" origin main

If C<--no-deploy> option is specified, "giblog deploy" is not executed.

  giblog all --no-deploy -m "Commit Messages" origin main

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

=head1 DOCUMENT

=over 2

=item * L<Giblog>

=item * L<Giblog::API>

=item * L<Giblog::Command>

=item * L<Giblog::Command::add>

=item * L<Giblog::Command::build>

=item * L<Giblog::Command::deploy>

=item * L<Giblog::Command::new>

=item * L<Giblog::Command::new_blog>

=item * L<Giblog::Command::new_website>

=item * L<Giblog::Command::publish>

=item * L<Giblog::Command::save>

=item * L<Giblog::Command::serve>

=back

=head1 FAQ

=head2 Dose Giblog support Windows?

Giblog doesn't support native Windows(Strawberry Perl, or Active Perl) because Giblog depends on L<Git|https://git-scm.com/> and L<Mojolicious>.

If you use Giblog in Windows, you can use L<msys2|https://www.msys2.org/> or WSL2.

=head2 What is the lowest version of Perl supported by Giblog?

The lowest version of Perl is the same version as L<Mojolicious> because Giblog depends on L<Mojolicious>. The current version is Perl 5.16+.

=head2 What is the lowest version of Git required by Giblog?

Git 1.8.5+.

=head2 What to consider when upgrading from Giblog 2 to Giblog 3?

Giblog 3.0 is compatible with Giblog 2.0. You can upgrade from Giblog 2.0 to Giblog 3.0 naturally.

=head2 What to consider when upgrading from Giblog 1 to Giblog 2?

From Giblog 2.0 the lowest version of Perl depends on L<Mojolicious>, so use the latest Perl as possible.

Git 1.8.5+ is required.

=head1 OFFICEAL SITE

L<Giblog Official Site|https://en.giblog.perlzemi.com/>

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 CONTRIBUTORS

Yasuaki Omokawa, C<< <omokawa at senk-inc.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2021 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
