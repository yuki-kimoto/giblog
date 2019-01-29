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
    
    my $url = $template_rel_file;
    $url =~ s|^templates||;
    if ($url eq '/index.html') {
      $url = '/';
    }
    
    my $data = {
      content => $content,
      url => $url,
    };
    
    # Parse template
    $data = $self->parse_template($data);
    
    # Build html
    $data = $self->build_html($data);
    
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

sub parse_template {
  my ($self, $data) = @_;
  
  $data ||= {};
  
  my $template_content = $data->{content};
  my $url = $data->{url};
  
  # Normalize line break;
  $template_content =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
  
  my @template_lines = split /\n/, $template_content;
  
  my $pre_start;
  my $entry_content = '';
  my $bread_end;
  for my $line (@template_lines) {
    my $original_line = $line;
    
    # Pre end
    if ($line =~ m|^</pre\b|) {
      $pre_start = 0;
    }
    
    # Escape >, < in pre tag
    if ($pre_start) {
      $line =~ s/>/&gt;/g;
      $line =~ s/</&lt;/g;
      $entry_content .= "$line\n";
    }
    else {
      # title
      if ($line =~ s|class="title"[^>]*?>([^<]*?)<|class="title"><a href="$url">$1</a><|) {
        my $title = $1;
        unless (defined $data->{'title'}) {
          $data->{'title'} = $1;
        }
      }
      
      # If start with inline tag, wrap p
      if ($line =~ $inline_elements_re) {
        $entry_content .= "<p>\n  $line\n</p>\n";
      }
      # If start with space or tab or not inline tag, it is raw line
      elsif ($line =~ /^[ \t\<]/) {
        $entry_content .= "$line\n";
      }
      # If line have length, wrap p
      else {
        if (length $line) {
          $entry_content .= "<p>\n  $line\n</p>\n";
        }
      }
    }

    # Pre start
    if ($original_line =~ m|^<pre\b|) {
      $pre_start = 1
    }
  }
  
  $data->{'content'} = $entry_content;
  
  return $data;
}

sub build_html {
  my ($self, $data) = @_;
  
  my $giblog = $self->giblog;
  
  my $page_title = $data->{'title'};
  my $config = $giblog->read_config;
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
  
  my $entry_content = $data->{content};
  
  my $common_meta_file = $giblog->rel_file('templates/common/meta.html');
  my $common_meta_content = $giblog->slurp_file($common_meta_file);

  my $common_header_file = $giblog->rel_file('templates/common/header.html');
  my $common_header_content = $giblog->slurp_file($common_header_file);

  my $common_footer_file = $giblog->rel_file('templates/common/footer.html');
  my $common_footer_content = $giblog->slurp_file($common_footer_file);

  my $common_side_file = $giblog->rel_file('templates/common/side.html');
  my $common_side_content = $giblog->slurp_file($common_side_file);

  my $common_entry_top_file = $giblog->rel_file('templates/common/entry-top.html');
  my $common_entry_top_content = $giblog->slurp_file($common_entry_top_file);

  my $common_entry_bottom_file = $giblog->rel_file('templates/common/entry-bottom.html');
  my $common_entry_bottom_content = $giblog->slurp_file($common_entry_bottom_file);
  
  my $html = <<"EOS";
<!DOCTYPE html>
<html>
  <head>
    $common_meta_content
    <title>$title</title>
  </head>
  <body>
    <div class="container">
      <div class="header">
        $common_header_content
      </div>
      <div class="main">
        <div class="entry">
          <div class="entry-top">
            $common_entry_bottom_content
          </div>
          <div class="entry-body">
            $entry_content
          </div>
          <div class="entry-bottom">
            $common_entry_bottom_content
          </div>
        </div>
        <div class="side">
          $common_side_content
        </div>
      </div>
      <div class="footer">
        $common_footer_content
      </div>
    </div>
  </body>
</html>
EOS
  
  $data->{content} = $html;
    
  return $data;
}

1;
