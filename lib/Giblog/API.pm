package Giblog::API;

use strict;
use warnings;
use File::Find 'find';
use File::Basename 'dirname', 'basename';
use File::Path 'mkpath';
use Carp 'confess';
use Encode 'encode', 'decode';
use File::Copy 'copy';

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, $class;
}

sub giblog { shift->{giblog} }

sub config { shift->giblog->config }

sub home_dir { shift->giblog->home_dir };

sub read_config {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  # Read config
  my $config;
  if (defined $giblog->{config}) {
    confess "Config is already loaded";
  }
  
  my $config_file = $self->rel_file('giblog.conf');
  
  my $config_content = $self->slurp_file($config_file);
  
  $config = eval $config_content
    or confess "Can't parse config file \"$config_file\":$@$!";
    
  unless (ref $config eq 'HASH') {
    confess "\"$config_file\" must end with hash reference";
  }
  
  $giblog->{config} = $config;
  
  return $config;
}

sub clear_config {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  $giblog->{config} = undef;
}

sub create_dir {
  my ($self, $dir) = @_;
  mkdir $dir
    or confess "Can't create directory \"$dir\": $!";
}

sub create_file {
  my ($self, $file) = @_;
  open my $fh, '>', $file
    or confess "Can't create file \"$file\": $!";
}

sub write_to_file {
  my ($self, $file, $content) = @_;
  open my $fh, '>', $file
    or confess "Can't create file \"$file\": $!";
  
  print $fh encode('UTF-8', $content);
}

sub slurp_file {
  my ($self, $file) = @_;

  open my $fh, '<', $file
    or confess "Can't read file \"$file\": $!";
  
  my $content = do { local $/; <$fh> };
  $content = decode('UTF-8', $content);
  
  return $content;
}

sub _get_proto_dir {
  my ($self, $module_name) = @_;
  
  my $proto_dir = $self->_module_rel_file($module_name, 'proto');
  
  return $proto_dir;
}

sub create_website_from_proto {
  my ($self, $home_dir, $module_name) = @_;
  
  unless (defined $home_dir) {
    confess "Home directory must be specified\n";
  }
  
  if (-f $home_dir) {
    confess "Home directory \"$home_dir\" is already exists\n";
  }
  
  my $proto_dir = $self->_get_proto_dir($module_name);
  
  unless (defined $proto_dir) {
    confess "proto diretory can't specific\n";
  }

  unless (-d $proto_dir) {
    confess "Can't find proto diretory $proto_dir\n";
  }

  # Create website directory
  $self->create_dir($home_dir);

  # Copy command proto files to user directory
  my @files;
  find(
    {
      wanted => sub {
        my $proto_file = $File::Find::name;
        
        # Skip directory
        return unless -f $proto_file;
        
        my $rel_file = $proto_file;
        $rel_file =~ s/^\Q$proto_dir\E[\/|\\]//;
        
        my $user_file = "$home_dir/$rel_file";
        my $user_dir = dirname $user_file;
        mkpath $user_dir;
        
        copy $proto_file, $user_file
          or die "Can't copy $proto_file to $user_file: $!";
        
        my @stat = stat $proto_file;
        my $permission = substr((sprintf "%03o", $stat[2]), -3);
        if (substr($permission, 0, 1) == 5) {
          substr($permission, 0, 1) = 7;
        }
        elsif (substr($permission, 0, 1) == 4) {
          substr($permission, 0, 1) = 6;
        }
        chmod oct($permission), $user_file
          or confess "Can't change permission: $!";
      },
      no_chdir => 1,
    },
    $proto_dir
  );
  
  # git init repository directory
  my @git_init_cmd_rep = ('git', 'init', $home_dir);
  system(@git_init_cmd_rep) == 0
    or confess "Can't execute command : @git_init_cmd_rep: $!";
  
  # git init public directory
  my @git_init_cmd_public = ('git', 'init', "$home_dir/public");
  system(@git_init_cmd_public) == 0
    or confess "Can't execute command : @git_init_cmd_public: $!";
}

sub rel_file {
  my ($self, $file) = @_;
  
  my $home_dir = $self->giblog->home_dir;
  
  if (defined $home_dir) {
    return "$home_dir/$file";
  }
  else {
    return $file;
  }
}

sub _module_rel_file {
  my ($self, $module_name, $rel_file) = @_;
  
  my $command_rel_path = $module_name;
  $command_rel_path =~ s/::/\//g;
  $command_rel_path .= '.pm';
  
  my $command_path = $INC{$command_rel_path};
  
  unless ($command_path) {
    confess "Can't get module path because module is not loaded";
  }
  
  my $command_dir = $command_path;
  $command_dir =~ s/\.pm$//;
  
  my $file = "$command_dir/$rel_file";
  
  return $file;
}

sub copy_static_files_to_public {
  my $self = shift;

  my $static_dir = $self->rel_file('templates/static');

  # Get static files
  my @static_rel_files;
  find(
    {
      wanted => sub {
        my $static_file = $File::Find::name;
        
        # Skip directory
        my $static_file_base = basename $_;
        
        my $static_rel_file = $static_file;
        $static_rel_file =~ s/^$static_dir//;
        $static_rel_file =~ s/^[\\\/]//;
        
        push @static_rel_files, $static_rel_file;
      },
      no_chdir => 1,
    },
    $static_dir
  );
  
  # Copy static content to public
  for my $static_rel_file (@static_rel_files) {
    my $static_file = $self->rel_file("templates/static/$static_rel_file");
    my $public_file = $self->rel_file("public/$static_rel_file");
    
    next unless -f $static_file;

    my $public_dir = dirname $public_file;
    mkpath $public_dir;
    
    copy $static_file, $public_file
      or confess "Can't copy $static_file to $public_file: $!";
    my @stat = stat $static_file;
    my $permission = substr((sprintf "%03o", $stat[2]), -3);
    chmod oct($permission), $public_file
      or confess "Can't change permission: $!";
  }
}

sub get_templates_files {
  my $self = shift;

  my $templates_dir = $self->rel_file('templates');

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

        # Skip static files
        return if $template_file =~ /^\Q$templates_dir\/static/;
        
        my $template_file_base = basename $_;
        
        # Skip hidden file
        return if $template_file_base =~ /^\./;
        
        my $template_rel_file = $template_file;
        $template_rel_file =~ s/^$templates_dir//;
        $template_rel_file =~ s/^[\\\/]//;
        
        push @template_rel_files, $template_rel_file;
      },
      no_chdir => 1,
    },
    $templates_dir
  );
  
  return \@template_rel_files;
}

sub get_content {
  my ($self, $data) = @_;
  
  my $file = $data->{file};
  
  my $template_file = $self->rel_file("templates/$file");
  my $content = $self->slurp_file($template_file);
  
  $data->{content} = $content;
}

my $inline_elements_re = qr/^<(span|em|strong|abbr|acronym|dfn|q|cite|sup|sub|code|var|kbd|samp|bdo|font|big|small|b|i|s|strike|u|tt|a|label|object|applet|iframe|button|textarea|select|basefont|img|br|input|map)\b/;

sub parse_giblog_syntax {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  
  my $content = $data->{content};

  # Normalize line break;
  $content =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
  
  # Parse Giblog syntax
  my @lines = split /\n/, $content;
  my $pre_start;
  $content = '';
  my $bread_end;
  for my $line (@lines) {
    my $original_line = $line;
    
    # Pre end
    if ($line =~ m|^</pre\b|) {
      $pre_start = 0;
    }
    
    # Escape >, < in pre tag
    if ($pre_start) {
      $line =~ s/&/&amp;/g;
      $line =~ s/>/&gt;/g;
      $line =~ s/</&lt;/g;
      $content .= "$line\n";
    }
    else {
      # If start with inline tag, wrap p
      if ($line =~ $inline_elements_re) {
        $content .= "<p>\n  $line\n</p>\n";
      }
      # If start with space or tab or not inline tag, it is raw line
      elsif ($line =~ /^[ \t\<]/) {
        $content .= "$line\n";
      }
      # If line have length, wrap p
      else {
        if (length $line) {
          $content .= "<p>\n  $line\n</p>\n";
        }
      }
    }

    # Pre start
    if ($original_line =~ m|^<pre\b|) {
      $pre_start = 1
    }
  }
  
  $data->{content} = $content;
}

sub parse_title {
  my ($self, $data) = @_;
  
  my $config = $self->config;

  my $content = $data->{content};
  
  if ($content =~ m|class="title"[^>]*?>([^<]*?)<|) {
    my $title = $1;
    $data->{title} = $title;
  }
  else {
    $data->{title} = undef;
  }
}

sub add_base_path_to_content {
  my ($self, $data) = @_;
  
  # Giblog
  my $giblog = $self->giblog;
  
  # Config
  my $config = $giblog->config;
  
  # Base path
  my $base_path = $config->{base_path};
  if (defined $base_path) {
    $self->_check_base_path($base_path);
    
    # Content
    my $content = $data->{content};

    # Add base path
    my @lines = split /\n/, $content;
    my $pre_start;
    $content = '';
    my $bread_end;
    for my $line (@lines) {
      my $original_line = $line;
      
      # Pre end
      if ($line =~ m|^</pre\b|) {
        $pre_start = 0;
      }
      
      # Don't add base path in pre tag
      if ($pre_start) {
        $content .= "$line\n";
      }
      # Add base path to absolute path
      else {
        # Add base path to href absolute path
        $line =~ s/\bhref\s*=\s*"(\/[^"]*?)"/href="$base_path$1"/g;
        
        # Add base path to src absolute path
        $line =~ s/\bsrc\s*=\s*"(\/[^"]*?)"/src="$base_path$1"/g;
        
        $content .= "$line\n";
      }
      
      # Pre start
      if ($original_line =~ m|^<pre\b|) {
        $pre_start = 1
      }
    }
    
    $data->{content} = $content;
  }
}

sub add_base_path_to_public_css_files {
  my ($self) = @_;
  
  # Giblog
  my $giblog = $self->giblog;
  
  # Config
  my $config = $giblog->config;
  
  # Base path
  my $base_path = $config->{base_path};
  if (defined $base_path) {
    
    $self->_check_base_path($base_path);
    
    my $public_dir = $self->rel_file('public');
    
    # Add base path to css file
    find(
      {
        wanted => sub {
          my $public_file = $File::Find::name;
          
          # Skip directory
          return if -d $public_file;
          
          # Skip not css file
          return unless $public_file =~ /\.css$/;
          
          # Open read-write mode
          open my $fh, "+<", $public_file
            or confess "Can't open \"$public_file\": $!";
          
          # Get content
          my $content = $self->slurp_file($public_file);
          
          # Add base path to href absolute path
          $content =~ s/\burl\s*\(\s*(\/[^\)]*?)\)/url($base_path$1)/g;
          
          print $fh encode('UTF-8', $content)
            or confess "Can't write content to $public_file: $!";
          
          close $fh
            or confess "Can't close file hanlde $public_file: $!";
        },
        no_chdir => 1,
      },
      $public_dir
    );
  }
}

sub _check_base_path {
  my ($self, $base_path) = @_;
  
  # Check base path
  unless ($base_path =~ /^\//) {
    confess "base_path must start /";
  }
  if ($base_path =~ /\/$/) {
    confess "base_path must end not /";
  }
}

sub parse_title_from_first_h_tag {
  my ($self, $data) = @_;
  
  my $config = $self->config;

  my $content = $data->{content};
  
  if ($content =~ m|<\s*h[1-6]\b[^>]*?>([^<]*?)<|) {
    my $title = $1;
    $data->{title} = $title;
  }
  else {
    $data->{title} = undef;
  }
}

sub add_page_link {
  my ($self, $data, $opt) = @_;

  $opt ||= {};

  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Add page link
  my $file = $data->{file};
  my $path;
  my $root = $opt->{root};
  if (defined $root) {
    if ($file eq $root) {
      $path = "/";
    }
    else {
      $path = "/$file";
    }
  }
  else {
    $path = "/$file";
  }
  
  $content =~ s|class="title"[^>]*?>([^<]*?)<|class="title"><a href="$path">$1</a><|;
  
  $data->{'content'} = $content;
}

sub add_page_link_to_first_h_tag {
  my ($self, $data, $opt) = @_;
  
  $opt ||= {};
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Add page link
  my $file = $data->{file};
  my $path;
  my $root = $opt->{root};
  if (defined $root) {
    if ($file eq $root) {
      $path = "/";
    }
    else {
      $path = "/$file";
    }
  }
  else {
    $path = "/$file";
  }
  
  $content =~ s|(<\s*h[1-6]\b[^>]*?>)([^<]*?)<|$1<a href="$path">$2</a><|;

  $data->{'content'} = $content;
}

sub parse_description {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  if ($content =~ m|class="description"[^>]*?>([^<]*?)<|s) {
    my $description = $1;

    # trim space
    $description =~ s/^\s+//;
    $description =~ s/\s+$//;

    $data->{'description'} = $description;
  }
  else {
    $data->{'description'} = undef;
  }
}

sub parse_description_from_first_p_tag {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Create description from first p tag
  if ($content =~ m|<\s?p\b[^>]*?>(.*?)<\s?/\s?p\s?>|s) {
    my $description = $1;
    
    # remove tag
    $description =~ s/<[^<]*?>//g;
    
    # trim space
    $description =~ s/^\s+//;
    $description =~ s/\s+$//;

    # remove new lines
    $description =~ s/\n//g;
    
    $data->{'description'} = $description;
  }
  else {
    $data->{'description'} = undef;
  }
}

sub parse_keywords {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};

  # keywords
  if ($content =~ m|class="keywords"[^>]*?>([^<]*?)<|) {
    my $keywords = $1;
    $data->{'keywords'} = $1;
  }
}

sub parse_first_img_src {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # image
  if ($content =~ /<\s*img\b.*?\bsrc\s*=\s*"([^"]*?)"/s) {
    my $image = $1;
    $data->{'img_src'} = $image;
  }
}

sub build_entry {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = <<"EOS";
<div class="entry">
  <div class="top">
    $data->{top}
  </div>
  <div class="middle">
    $data->{content}
  </div>
  <div class="bottom">
    $data->{bottom}
  </div>
</div>
EOS
  
  $data->{content} = $content;
}

sub build_html {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = <<"EOS";
<!DOCTYPE html>
<html>
  <head>
    $data->{meta}
  </head>
  <body>
    <div class="container">
      <div class="header">
        $data->{header}
      </div>
      <div class="main">
        <div class="content">
          $data->{content}
        </div>
        <div class="side">
          $data->{side}
        </div>
      </div>
      <div class="footer">
        $data->{footer}
      </div>
    </div>
  </body>
</html>
EOS
  
  $data->{content} = $content;
}

sub add_meta_title {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  
  my $meta = $data->{meta};
  
  # Title
  my $title = $data->{title};
  if (defined $title) {
    $meta .= "\n<title>$title</title>";
  }
  
  $data->{meta} = $meta;
}

sub add_meta_description {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  
  my $meta = $data->{meta};
  
  # Title
  my $description = $data->{description};
  if (defined $description) {
    $meta .= qq(\n<meta name="description" content="$description">);
  }
  
  $data->{meta} = $meta;
}

sub read_common_templates {
  my ($self, $data) = @_;
  
  my $common_meta_file = $self->rel_file('templates/common/meta.html');
  my $common_meta_content = $self->slurp_file($common_meta_file);
  $data->{meta} = $common_meta_content;

  my $common_header_file = $self->rel_file('templates/common/header.html');
  my $common_header_content = $self->slurp_file($common_header_file);
  $data->{header} = $common_header_content;

  my $common_footer_file = $self->rel_file('templates/common/footer.html');
  my $common_footer_content = $self->slurp_file($common_footer_file);
  $data->{footer} = $common_footer_content;

  my $common_side_file = $self->rel_file('templates/common/side.html');
  my $common_side_content = $self->slurp_file($common_side_file);
  $data->{side} = $common_side_content;

  my $common_top_file = $self->rel_file('templates/common/top.html');
  my $common_top_content = $self->slurp_file($common_top_file);
  $data->{top} = $common_top_content;

  my $common_bottom_file = $self->rel_file('templates/common/bottom.html');
  my $common_bottom_content = $self->slurp_file($common_bottom_file);
  $data->{bottom} = $common_bottom_content;
}

sub write_to_public_file {
  my ($self, $data) = @_;
  
  my $content = $data->{content};
  my $file = $data->{file};
  
  # public file
  my $public_file = $self->rel_file("public/$file");
  my $public_dir = dirname $public_file;
  mkpath $public_dir;
  
  # Need update public file
  my $is_need_update_public_file;
  if (!-f $public_file) {
    $is_need_update_public_file = 1;
  }
  else {
    # Get original content
    my $original_content = $self->slurp_file($public_file);
    unless ($content eq $original_content) {
      $is_need_update_public_file = 1;
    }
  }
  
  # Write to public file
  if ($is_need_update_public_file) {
    $self->write_to_file($public_file, $content);
  }
}

1;

=head1 NAME

Giblog::API - Giblog API

=head1 DESCRIPTION

Giblog::API defines sevral methods to manipulate HTML contents.

=head1 METHODS

=head2 new

  my $api = Giblog::API->new(%params);

Create L<Giblog::API> object.

B<Parameters:>

=over 4

=item * giblog

Set L<Giblog> object.

By C<giblog> method, you can access this parameter.

  my $giblog = $api->giblog;

=back

=head2 giblog

  my $giblog = $api->giblog;

Get L<Giblog> object.

=head2 config

  my $config = $api->config;

Get Giblog config. This is hash reference.

Config is loaded by C<read_config> method.

If config is not loaded, this method return undef.

=head2 home_dir

  my $home_dir = $api->home_dir;

Get home directory.

=head2 read_config

  my $config = $api->read_config;

Parse "giblog.conf" in home directory and return hash reference.

"giblog.conf" must end with correct hash reference. Otherwise exception occur.
  
  # giblog.conf
  {
    site_title => 'mysite',
    site_url => 'http://somesite.example',
  }

After calling "read_config", You can also get config by C<config> method.

=head2 clear_config

  $api->clear_config;

Clear config. Set undef to config.

=head2 create_dir

  $api->create_dir($dir);

Create directory.

If Creating directory fail, exception occur.

=head2 create_file

  $api->create_file($file);

Create file.

If Creating file fail, exception occur.

=head2 write_to_file

  $api->write_to_file($file, $content);

Write content to file. Content is encoded to UTF-8.

If file is not exists, file is created automatically.

If Creating file fail, exception occur.

=head2 slurp_file

  my $content = $api->slurp_file($file);

Get file content. Content is decoded from UTF-8.

If file is not exists, exception occur.

=head2 rel_file

  my $file = $api->rel_file('foo/bar');

Get combined path of home directory and specific relative path.

If home directory is not set, return specific path.

=head2 create_website_from_proto

  $api->create_website_from_proto($home_dir, $module_name);

Create website home directory and copy files from prototype directory.

Prototype directory is automatically detected from module name.

If module name is "Giblog::Command::new_foo" and the loading path is "lib/Giblog/Command/new_foo.pm", path of prototype directory is "lib/Giblog/Command/new_foo/proto".

  lib/Giblog/Command/new_foo.pm
                    /new_foo/proto

Module must be loaded before calling "create_website_from_proto". otherwise exception occur.

The web site directry is initialized by git and C<public> direcotry is also initialized by git.

  git init foo
  git init foo/public 
  
If home directory is not specific, a exception occurs.

If home directory already exists, a exception occurs.

If creating directory fail, a exception occurs.

If proto directory corresponding to module name is not specific, a exception occurs.

If proto direcotry corresponding to module name is not found, a exception occurs.

If git command is not found, a exception occurs.

=head2 copy_static_files_to_public

  $api->copy_static_files_to_public;

Copy static files in "templates/static" directory to "public" directory.

=head2 get_templates_files

  my $files = $api->get_templates_files;

Get file names in "templates" directory in home directory.

Files in "templates/common" directory and "templates/static" directory and hidden files(which start with ".") is not contained.

Got file name is relative name from "templates" directory.

For example,

  index.html
  blog/20190312121345.html
  blog/20190314452341.html

=head2 get_content

  $api->get_content($data);

Get content from relative file name from "templates" directory. Content is decoded from UTF-8.

B<INPUT:>

  $data->{file}

B<OUTPUT:>

  $data->{content}
  
B<Example:>
  
  # Get content from templates/index.html
  $data->{file} = 'index.html';
  $api->get_content($data);
  my $content = $data->{content};

=head2 parse_giblog_syntax

  $api->parse_giblog_syntax($data);

Parse input text as "Giblog syntax", and return output.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{content}
  
B<Example:>
  
  # Parse input as giblog syntax
  $data->{content} = <<'EOS';
  Hello World!

  <b>Hi, Yuki</b>

  <div>
    OK
  </div>

  <pre>
  my $foo = 1 > 3 && 2 < 5;
  </pre>
  EOS
  
  $api->parse_giblog_syntax($data);
  my $content = $data->{content};

B<Giblog syntax>

Giblog syntax is simple syntax to write content easily.

=over 4

=item 1. Add p tag automatically

Add p tag to inline element starting from the beginning of line.

  # Input
  Hello World!
  
  <b>Hi, Yuki</b>
  
  <div>
    OK
  </div>
  
  # Output
  <p>
    Hello World!
  </p>
  <p>
    <b>Hi, Yuki</b>
  </p>
  <div>
    OK
  </div>

Empty line is deleted.

=item 2. Escape E<gt>, E<lt>, & in pre tag

If pre tag starts at the beginning of the line and its end tag starts at the beginning of the line, execute HTML escapes ">" and "<" between them.
  
  # Input
  <pre>
  my $foo = 1 > 3 && 2 < 5;
  </pre>

  # Output
  <pre>
  my $foo = 1 &gt; 3 &amp;&amp; 2 &lt; 5;
  </pre>

=back

=head2 parse_title

  $api->parse_title($data);

Get title from text of tag which class name is "title".

If parser can't get title, title become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{title}

B<Example:>
  
  # Get title
  $data->{content} = <<'EOS';
  <div class="title">Perl Tutorial</div>
  EOS
  $api->parse_title($data);
  my $title = $data->{title};

=head2 parse_title_from_first_h_tag

  $api->parse_title_from_first_h_tag($data);

Get title from text of first h1, h2, h3, h4, h5, h6 tag.

If parser can't get title, title become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{title}

B<Example:>
  
  # Get title
  $data->{content} = <<'EOS';
  <h1>Perl Tutorial</h1>
  EOS
  $api->parse_title_from_first_h_tag($data);
  my $title = $data->{title};

=head2 add_page_link

  $api->add_page_link($data);
  $api->add_page_link($data, $opt);

Add page link to text of tag which class name is "title".

If parser can't get title, content is not changed.

B<INPUT:>

  $data->{file}
  $data->{content}

B<OUTPUT:>

  $data->{content}

"file" is relative path from "templates" directory.

If added link is the path which combine "/" and value of "file".

if $opt->{root} is specifed and this match $data->{file}, added link is "/".

B<Example:>
  
  # Add page link
  $data->{file} = 'blog/20181012123456.html';
  $data->{content} = <<'EOS';
  <div class="title">Perl Tutorial</div>
  EOS
  $api->add_page_link($data);
  my $content = $data->{content};

Content is changed to

  <div class="title"><a href="/blog/20181012123456.html">Perl Tutorial</a></div>

B<Example: root page>

  # Add page link
  $data->{file} = 'index.html';
  $data->{content} = <<'EOS';
  <div class="title">Perl Tutorial</div>
  EOS
  $api->add_page_link($data);
  my $content = $data->{content};

Content is changed to

  <div class="title"><a href="/">Perl Tutorial</a></div>

=head2 add_page_link_to_first_h_tag

  $api->add_page_link_to_first_h_tag($data);
  $api->add_page_link_to_first_h_tag($data, $opt);

Add page link to text of first h1, h2, h3, h4, h5, h6 tag.

If parser can't get title, content is not changed.

B<INPUT:>

  $data->{file}
  $data->{content}

B<OUTPUT:>

  $data->{content}

"file" is relative path from "templates" directory.

If added link is the path which combine "/" and value of "file".

if $opt->{root} is specifed and this match $data->{file}, added link is "/".

B<Example: entry page>
  
  # Add page link
  $data->{file} = 'blog/20181012123456.html';
  $data->{content} = <<'EOS';
  <h1>Perl Tutorial</h1>
  EOS
  $api->add_page_link_to_first_h_tag($data);
  my $content = $data->{content};

Content is changed to

  <h1><a href="/blog/20181012123456.html">Perl Tutorial</a></h1>

B<Example: root>

  # Add page link
  $data->{file} = 'index.html';
  $data->{content} = <<'EOS';
  <h1>Perl Tutorial</h1>
  EOS
  $api->add_page_link_to_first_h_tag($data);
  my $content = $data->{content};

Content is changed to

  <h1><a href="/">Perl Tutorial</a></h1>

=head2 parse_description

  $api->parse_description($data);

Get description from text of tag which class name is "description".

Both of left spaces and right spaces are removed. This is Unicode space.

If parser can't get description, description become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{description}

B<Example:>
  
  # Get description
  $data->{content} = <<'EOS';
  <div class="description">
    Perl Tutorial is site for beginners of Perl 
  </div>
  EOS
  $api->parse_description($data);
  my $description = $data->{description};

Output description is "Perl Tutorial is site for beginners of Perl".

=head2 parse_description_from_first_p_tag

  $api->parse_description_from_first_p_tag($data);

Get description from text of first p tag.

HTML tag is removed.

Both of left spaces and right spaces is removed. This is Unicode space.

If parser can't get description, description become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{description}

B<Example:>
  
  # Get description
  $data->{content} = <<'EOS';
  <p>
    Perl Tutorial is site for beginners of Perl 
  </p>
  <p>
    Foo, Bar
  </p>
  EOS
  $api->parse_description_from_first_p_tag($data);
  my $description = $data->{description};

Output description is "Perl Tutorial is site for beginners of Perl".

=head2 parse_keywords

  $api->parse_keywords($data);

Get keywords from text of tag which class name is "keywords".

If parser can't get keywords, keywords become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{keywords}

B<Example:>
  
  # Get keywords
  $data->{content} = <<'EOS';
  <div class="keywords">Perl,Tutorial</div>
  EOS
  $api->parse_keywords($data);
  my $keywords = $data->{keywords};

=head2 parse_first_img_src

  $api->parse_first_img_src($data);

Get image src from src attribute of first img tag.

If parser can't get image src, image src become undef.

B<INPUT:>

  $data->{content}

B<OUTPUT:>

  $data->{img_src}

B<Example:>
  
  # Get first_img_src
  $data->{content} = <<'EOS';
<img class="ppp" src="/path">
  EOS
  $api->parse_first_img_src($data);
  my $img_src = $data->{img_src};

Output img_src is "/path".

=head2 read_common_templates

  $api->read_common_templates($data);

Read common templates in "templates/common" directory.

The follwoing templates is loaded. Content is decoded from UTF-8.

"meta.html", "header.html", "footer.html", "side.html", "top.html", "bottom.html"

B<OUTPUT:>

  $data->{meta}
  $data->{header}
  $data->{footer}
  $data->{side}
  $data->{top}
  $data->{bottom}

=head2 add_meta_title

Add title tag to meta section.

B<INPUT:>

  $data->{title}
  $data->{meta}

B<OUTPUT:>

  $data->{meta}

If value of "meta" is "foo" and "title" is "Perl Tutorial", output value of "meta" become "foo\n<title>Perl Tutorial</title>"

=head2 add_meta_description

Add meta description tag to meta section.

B<INPUT:>

  $data->{description}
  $data->{meta}

B<OUTPUT:>

  $data->{meta}

If value of "meta" is "foo" and "description" is "Perl is good", output value of "meta" become "foo\n<meta name="description" content="Perl is good">"

=head2 build_entry

Build entry HTML by "content" and "top", "bottom".

B<INPUT:>

  $data->{content}
  $data->{top}
  $data->{bottom}

B<OUTPUT:>

  $data->{content}

Output is the following HTML.

  <div class="entry">
    <div class="top">
      $data->{top}
    </div>
    <div class="middle">
      $data->{content}
    </div>
    <div class="bottom">
      $data->{bottom}
    </div>
  </div>

=head2 build_html

Build whole HTML by "content" and "header", "bottom", "side", "footer".

B<INPUT:>

  $data->{content}
  $data->{header}
  $data->{bottom}
  $data->{side}
  $data->{footer}

B<OUTPUT:>

  $data->{content}

Output is the following HTML.

  <!DOCTYPE html>
  <html>
    <head>
      $data->{meta}
    </head>
    <body>
      <div class="container">
        <div class="header">
          $data->{header}
        </div>
        <div class="main">
          <div class="content">
            $data->{content}
          </div>
          <div class="side">
            $data->{side}
          </div>
        </div>
        <div class="footer">
          $data->{footer}
        </div>
      </div>
    </body>
  </html>

=head2 write_to_public_file

Write content to file in "public" directory. Content is encoded to UTF-8.

If value of "file" is "index.html", write path become "public/index.html"

B<INPUT:>

  $data->{content}
  $data->{file}

If the original content of the file is same as the new content of the file is same, this method don't write to public file. This means file time stamp is not be updated.
