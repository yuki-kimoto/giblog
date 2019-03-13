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

sub giblog_dir { shift->giblog->giblog_dir };

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
    or confess "Can't parse config file \"$config_file\"";
    
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

sub run_command {
  my ($self, $command_name, @argv) = @_;
  
  # Command is implemented in command
  my $command_class = "Giblog::Command::$command_name";
  eval "use $command_class;";
  if ($@) {
    confess "Can't load command $command_class:\n$!\n$@";
  }
  my $command = $command_class->new(api => $self);

  $command->run(@argv);
}

sub _get_proto_dir {
  my ($self, $module_name) = @_;
  
  my $proto_dir = $self->_module_rel_file($module_name, 'proto');
  
  return $proto_dir;
}

sub create_website_from_proto {
  my ($self, $home_dir, $module_name) = @_;
  
  unless (defined $home_dir) {
    confess "Home directory must be specifed\n";
  }
  
  if (-f $home_dir) {
    confess "Home directory \"$home_dir\" is already exists\n";
  }
  
  my $proto_dir = $self->_get_proto_dir($module_name);
  
  unless (defined $proto_dir) {
    confess "proto diretory can't specified\n";
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
          or confess "Can't copy $proto_file to $user_file: $!";
      },
      no_chdir => 1,
    },
    $proto_dir
  );
}

sub rel_file {
  my ($self, $file) = @_;
  
  my $giblog_dir = $self->giblog->giblog_dir;
  
  if (defined $giblog_dir) {
    return "$giblog_dir/$file";
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

sub write_to_public_file {
  my ($self, $data) = @_;
  
  my $content = $data->{content};
  my $file = $data->{file};
  
  # public file
  my $public_file = $self->rel_file("public/$file");
  my $public_dir = dirname $public_file;
  mkpath $public_dir;
  
  # Write to public file
  $self->write_to_file($public_file, $content);
}

my $inline_elements_re = qr/^<(span|em|strong|abbr|acronym|dfn|q|cite|sup|sub|code|var|kbd|samp|bdo|font|big|small|b|i|s|strike|u|tt|a|label|object|applet|iframe|button|textarea|select|basefont|img|br|input|script|map)\b/;

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
  
  unless (defined $data->{'title'}) {
    if ($content =~ m|class="title"[^>]*?>([^<]*?)<|) {
      my $title = $1;
      $data->{title} = $title;
    }
  }
}

sub parse_title_from_first_h_tag {
  my ($self, $data) = @_;
  
  my $config = $self->config;

  my $content = $data->{content};
  
  unless (defined $data->{'title'}) {
    if ($content =~ m|<\s*h[1-6]\b[^>]*?>([^<]*?)<|) {
      my $title = $1;
      $data->{title} = $title;
    }
  }
}

sub add_page_link_to_first_h_tag {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Add page link
  my $file = $data->{file};
  my $path;
  if ($file eq 'index.html') {
    $path = '/';
  }
  else {
    $path = "/$file";
  }
  
  $content =~ s|(<\s*h[1-6]\b[^>]*?>)([^<]*?)<|$1<a href="$path">$2</a><|;

  $data->{'content'} = $content;
}

sub add_page_link {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Add page link
  my $file = $data->{file};
  my $path;
  if ($file eq 'index.html') {
    $path = '/';
  }
  else {
    $path = "/$file";
  }
  
  $content =~ s|class="title"[^>]*?>([^<]*?)<|class="title"><a href="$path">$1</a><|;

  $data->{'content'} = $content;
}

sub parse_description {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  if ($content =~ m|class="description"[^>]*?>([^<]*?)<|) {
    my $description = $1;
    unless (defined $data->{'description'}) {
      $data->{'description'} = $description;
    }
  }
}

sub parse_description_from_first_p_tag {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # Create description from first p tag
  unless (defined $data->{'description'}) {
    if ($content =~ m|<\s?p\b[^>]*?>(.*?)<\s?/\s?p\s?>|s) {
      my $description = $1;
      # remove tag
      $description =~ s/<.*?>//g;
      
      # trim space
      $description =~ s/^\s+//;
      $description =~ s/\s+$//;
      
      $data->{'description'} = $description;
    }
  }
}

sub parse_keywords {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};

  # keywords
  if ($content =~ m|class="keywords"[^>]*?>([^<]*?)<|) {
    my $keywords = $1;
    unless (defined $data->{'keywords'}) {
      $data->{'keywords'} = $1;
    }
  }
}

sub parse_first_img_src {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;

  my $content = $data->{content};
  
  # image
  if ($content =~ /<\s*img\b.*?\bsrc\s*=\s*"([^"]*?)"/s) {
    my $image = $1;
    unless (defined $data->{'image'}) {
      $data->{'image'} = $image;
    }
  }
}

sub wrap {
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
        <div class="entry">
          <div class="top">
            $data->{top}
          </div>
          <div class="content">
            $data->{content}
          </div>
          <div class="bottom">
            $data->{bottom}
          </div>
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
    $meta .= "\n<title>$title</title>\n";
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
    $meta .= qq(\n<meta name="description" content="$description">\n);
  }
  
  $data->{meta} = $meta;
}

sub prepare_wrap {
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

=head2 giblog_dir

  my $giblog_dir = $api->giblog_dir;

Get Giblog home directory.

=head2 read_config

  my $config = $api->read_config;

Parse "giblog.conf" in Giblog home directory and return hash reference.

"giblog.conf" must end with correct hash reference.
  
  # giblog.conf
  {
    site_title => 'mysite',
    site_url => 'http://somesite.example',
  }

Otherwise exception occur.

After calling read_config, You can also get config by C<config> method.

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

Get combined path of giblog home directory and specified relative path.

If home directory is not set, return specified path.

=head2 run_command

  $api->run_command($command_name, @args);

Load command class and create object and execute "run" method.

For example, if command name is "build", then "Giblog::Command::build" is loaded, and the object is created and, "run" method is executed.

If module loading fail, exception occur.

=head2 create_website_from_proto

  $api->create_website_from_proto($home_dir, $module_name);

Create website home directory and copy files from prototype directory.

Prototype directory is automatically detected from module name.

If module name is "Giblog::Command::new_foo" and loading path is "lib/Giblog/Command/new_foo.pm", path of prototype directory is "lib/Giblog/Command/new_foo/proto".

  lib/Giblog/Command/new_foo.pm
                    /new_foo/proto

Module must be loaded before calling "create_website_from_proto". otherwise exception occur.

If home directory is not specified, exception occur.

If home directory already exists, exception occur.

If creating directory fail, exception occur.

If proto directory corresponding to module name is not specified, exception occur.

If proto direcotry corresponding to module name is not found, exception occur.

=head2 get_templates_files

=head2 get_content

=head2 parse_giblog_syntax

=head2 parse_title

=head2 add_page_link

=head2 parse_description

=head2 parse_description_from_first_p_tag

=head2 parse_keywords

=head2 parse_first_img_src

=head2 wrap

=head2 add_meta_title

=head2 add_meta_description

=head2 prepare_wrap

=head2 write_to_public_file
