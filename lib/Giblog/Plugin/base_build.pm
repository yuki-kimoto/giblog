package Giblog::Plugin::base_build;

use base 'Giblog::Plugin';

use strict;
use warnings;
use File::Find 'find';
use Carp 'confess';
use File::Basename 'dirname';
use File::Path 'mkpath';
use Encode 'encode', 'decode';

sub plugin {
  my $self = shift;
  
  $self->build;
}

sub build {
  my ($self) = @_;
  
  my $giblog = $self->giblog;

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

        # Skip common files
        return if $template_file =~ /^\Q$templates_dir\/common/;
                
        push @template_files, $template_file;
      },
      no_chdir => 1,
    },
    $templates_dir
  );
  
  for my $template_file (@template_files) {
    # Build html
    my $html = $self->build_html($templates_dir, $template_file);
    
    # public file
    my $public_rel_file = $template_file;
    $public_rel_file =~ s/^$templates_dir//;
    $public_rel_file =~ s/^\///;
    my $public_file = $giblog->rel_file("public/$public_rel_file");
    my $public_dir = dirname $public_file;
    mkpath $public_dir;
    
    $giblog->write_to_file($public_file, $html);
  }
}

my $inline_elements_re = qr/^<(span|em|strong|abbr|acronym|dfn|q|cite|sup|sub|code|var|kbd|samp|bdo|font|big|small|b|i|s|strike|u|tt|a|label|object|applet|iframe|button|textarea|select|basefont|img|br|input|script|map)\b/;

sub parse_template {
  my ($self, $template_content) = @_;
 
  # Normalize line break;
  $template_content =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
  
  my @template_lines = split /\n/, $template_content;
  
  my $pre_start;
  my $entry_content = '';
  my $bread_end;
  my $opt = {};
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
      if ($line =~ /class="title"[^>]*?>([^<]*?)</) {
        unless (defined $opt->{'giblog.title'}) {
          $opt->{'giblog.title'} = $1;
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
  
  $opt->{'giblog.entry'} = $entry_content;
  
  return $opt;
}

sub build_html {
  my ($self, $templates_dir, $template_file) = @_;
  
  my $giblog = $self->giblog;
  
  open my $tempalte_fh, '<', $template_file
      or confess "Can't open file \"$template_file\": $!";
  my $template_content = do { local $/; <$tempalte_fh> };
  $template_content = decode('UTF-8', $template_content);
  
  my $parse_result = $self->parse_template($template_content);
  my $page_title = $parse_result->{'giblog.title'};
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
  
  my $entry_content = delete $parse_result->{'giblog.entry'};
  
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
    
  return $html;
}

1;
