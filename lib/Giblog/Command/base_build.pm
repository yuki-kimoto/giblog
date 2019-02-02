package Giblog::Command::base_build;

use base 'Giblog::Command';

use strict;
use warnings;
use File::Find 'find';
use Carp 'confess';
use File::Basename 'dirname';
use File::Path 'mkpath';
use Encode 'encode', 'decode';

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
    
    # Parse template
    $self->parse_content($data);
    
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

my $inline_elements_re = qr/^<(span|em|strong|abbr|acronym|dfn|q|cite|sup|sub|code|var|kbd|samp|bdo|font|big|small|b|i|s|strike|u|tt|a|label|object|applet|iframe|button|textarea|select|basefont|img|br|input|script|map)\b/;

sub build_html {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  
  my $content = $data->{content};
  
  my $common_meta_file = $giblog->rel_file('templates/common/meta.html');
  my $common_meta_content = $giblog->slurp_file($common_meta_file);
  $data->{meta} = $common_meta_content;

  my $common_header_file = $giblog->rel_file('templates/common/header.html');
  my $common_header_content = $giblog->slurp_file($common_header_file);
  $data->{header} = $common_header_content;

  my $common_footer_file = $giblog->rel_file('templates/common/footer.html');
  my $common_footer_content = $giblog->slurp_file($common_footer_file);
  $data->{footer} = $common_footer_content;

  my $common_side_file = $giblog->rel_file('templates/common/side.html');
  my $common_side_content = $giblog->slurp_file($common_side_file);
  $data->{side} = $common_side_content;

  my $common_top_file = $giblog->rel_file('templates/common/top.html');
  my $common_top_content = $giblog->slurp_file($common_top_file);
  $data->{top} = $common_top_content;

  my $common_bottom_file = $giblog->rel_file('templates/common/bottom.html');
  my $common_bottom_content = $giblog->slurp_file($common_bottom_file);
  $data->{bottom} = $common_bottom_content;
  
  $self->parse_common($data);
  
  my $html = <<"EOS";
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
  
  $data->{content} = $html;
    
  return $data;
}

sub parse_content {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  my $config = $giblog->config;
  
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

  # title
  my $path = $data->{path};
  my $path_tmp = $path;
  unless (defined $path_tmp) {
    $path_tmp = '';
  }
  if ($content =~ s|class="title"[^>]*?>([^<]*?)<|class="title"><a href="$path_tmp">$1</a><|) {
    my $page_title = $1;
    unless (defined $data->{'title_original'}) {
      $data->{'title_original'} = $page_title;
    }
    unless (defined $data->{'title'}) {
      # Add site title after title
      my $site_title = $config->{site_title};
      my $title;
      if (length $page_title) {
        if (length $site_title) {
          $title = "$page_title - $site_title";
        }
        else {
          $title = $page_title;
        }
      }
      else {
        if (length $site_title) {
          $title = $site_title;
        }
        else {
          $title = '';
        }
      }
      $data->{title} = $title;
    }
  }

  # description
  if ($content =~ m|class="description"[^>]*?>([^<]*?)<|) {
    my $description = $1;
    unless (defined $data->{'description_original'}) {
      $data->{'description_original'} = $description;
    }
    unless (defined $data->{'description'}) {
      $data->{'description'} = $description;
    }
  }
  
  # Create description from first p tag
  unless (defined $data->{'description'}) {
    if ($content =~ m|<\s?p\b[^>]*?>\s*([^<]*?)\s*<\s?/\s?p\s?>|s) {
      $data->{'description'} = $1;
    }
  }

  # keywords
  if ($content =~ m|class="keywords"[^>]*?>([^<]*?)<|) {
    my $keywords = $1;
    unless (defined $data->{'keywords'}) {
      $data->{'keywords'} = $1;
    }
  }

  # image
  if ($content =~ /<\s*img\b.*?\bsrc\s*=\s*"([^"]*?)"/s) {
    my $image = $1;
    unless (defined $data->{'image'}) {
      $data->{'image'} = $image;
    }
  }
      
  
  $data->{'content'} = $content;
}

sub parse_common {
  my ($self, $data) = @_;
  
  # Giblog
  my $giblog = $self->giblog;
  
  # Config
  my $config = $giblog->config;
  
  # meta
  {
    my $meta = $data->{meta};
    
    # Title
    my $title = $data->{title};
    if (defined $title) {
      $meta .= "\n<title>$title</title>\n";
    }
    
    # Decription
    my $description = $data->{description};
    if (defined $description) {
      $meta .= qq(\n<meta name="description" content="$description">\n);
    }
    
    $data->{meta} = $meta;
  }
}

1;
