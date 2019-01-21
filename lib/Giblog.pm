package Giblog;

use 5.008007;
use strict;
use warnings;
use Carp 'confess';
use File::Find 'find';
use File::Basename 'basename', 'dirname';
use File::Path 'mkpath';
use Encode 'encode', 'decode';

=head1 NAME

Giblog - Static HTML Generator in Git and SmartPhone age

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub read_config {
  my $self = shift;
  
  my $config_file = $self->rel_file('giblog.conf');
  
  my $config_content = $self->slurp_file($config_file);
  $config_content = decode('UTF-8', $config_content);
  
  my $config = eval $config_content
    or confess "Can't parse config file \"$config_file\"";
  
  return $config;
}

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, $class;
}

sub giblog_dir {
  my $self = shift;
  
  return $self->{'giblog-dir'};
}

sub rel_file {
  my ($self, $file) = @_;
  
  my $giblog_dir = $self->giblog_dir;
  
  if (defined $giblog_dir) {
    return "$giblog_dir/$file";
  }
  else {
    return $file;
  }
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
  
  return $content;
}

sub parse_entry_file {
  my ($self, $template_file) = @_;
  
  open my $fh, '<', $template_file
    or confess "Can't open file \"$template_file\": $!";
  
  my $entry_content = '';
  my $bread_end;
  my $opt = {};
  while (my $line = <$fh>) {
    $line = decode('UTF-8', $line);
    
    $line =~ tr/\x0D\x0A//d;
    
    # title
    if ($line =~ /class="title"[^>]*?>([^<]*?)</) {
      unless (defined $opt->{'giblog.title'}) {
        $opt->{'giblog.title'} = $1;
      }
    }
    
    # Row line if first charcter is not space or tab
    if ($line =~ /^[ \t\<]/) {
      $entry_content .= "$line\n";
    }
    # Wrap p if line have length
    else {
      if (length $line) {
        $entry_content .= "<p>\n  $line\n</p>\n";
      }
    }
  }
  
  $opt->{'giblog.entry'} = $entry_content;
  
  return $opt;
}

sub build_public_file {
  my ($self, $templates_dir, $template_file) = @_;
  my $public_rel_file = $template_file;
  $public_rel_file =~ s/^$templates_dir//;
  $public_rel_file =~ s/^\///;
  $public_rel_file =~ s/\.tmpl\.html$/.html/;
  
  my $public_file = $self->rel_file("public/$public_rel_file");
  my $public_dir = dirname $public_file;
  mkpath $public_dir;
  
  my $parse_result = $self->parse_entry_file($template_file);
  my $page_title = $parse_result->{'giblog.title'};
  my $config = $self->read_config;
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
  
  my $h1_text;
  if (defined $page_title) {
    $h1_text = $page_title;
  }
  else {
    $h1_text = '';
  }
  
  my $entry_content = delete $parse_result->{'giblog.entry'};
  
  my $common_meta_file = $self->rel_file('common/meta.tmpl.html');
  my $common_meta_content = $self->slurp_file($common_meta_file);

  my $common_header_file = $self->rel_file('common/header.tmpl.html');
  my $common_header_content = $self->slurp_file($common_header_file);

  my $common_footer_file = $self->rel_file('common/footer.tmpl.html');
  my $common_footer_content = $self->slurp_file($common_footer_file);

  my $common_side_file = $self->rel_file('common/side.tmpl.html');
  my $common_side_content = $self->slurp_file($common_side_file);

  my $common_entry_top_file = $self->rel_file('common/entry-top.tmpl.html');
  my $common_entry_top_content = $self->slurp_file($common_entry_top_file);

  my $common_entry_bottom_file = $self->rel_file('common/entry-bottom.tmpl.html');
  my $common_entry_bottom_content = $self->slurp_file($common_entry_bottom_file);
  
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
          <h1>$h1_text</h1>
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
    
  $self->write_to_file($public_file, $html);

}

sub new_entry {
  my $self = shift;
  
  my $entry_dir = $self->rel_file('templates/blog');
  
  # Data and time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  $year += 1900;
  $mon++;
  my $datetime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  
  my $entry_file = "$entry_dir/$datetime.tmpl.html";
  my $entry = <<"EOS";
<!-- /blog/$datetime -->

EOS
  $self->write_to_file($entry_file, $entry);
}

sub config {
  my ($self, $site_name) = @_;
  
  my $config = <<"EOS";
{
  site_title => '$site_name',
}
EOS
  
  return $config;
}

sub common_css {
  my $common_css =<<"EOS";
  /*
    Default CSS settings
  */
  * {
    margin:0;
    padding:0;
    
    /* box-sizing: border-box */
    -moz-box-sizing: border-box;
    -webkit-box-sizing:border-box;
    box-sizing: border-box;
    
    /* text-size-adjust: 100% */
    -webkit-text-size-adjust: 100%;
    -moz-text-size-adjust: 100%;
    -ms-text-size-adjust: 100%;
    -o-text-size-adjust: 100%;
    text-size-adjust: 100%;
  }
  
  
  /* http://meyerweb.com/eric/tools/css/reset/ v2.0 | 20110126 License: none (public domain) */
  html, body, div, span, applet, object, iframe,
  h1, h2, h3, h4, h5, h6, p, blockquote, pre,
  a, abbr, acronym, address, big, cite, code,
  del, dfn, em, img, ins, kbd, q, s, samp,
  small, strike, strong, sub, sup, tt, var,
  b, u, i, center,
  dl, dt, dd, ol, ul, li,
  fieldset, form, label, legend,
  table, caption, tbody, tfoot, thead, tr, th, td,
  article, aside, canvas, details, embed, 
  figure, figcaption, footer, header, hgroup, 
  menu, nav, output, ruby, section, summary,
  time, mark, audio, video {
    margin: 0;
    padding: 0;
    border: 0;
    font-size: 100%;
    font: inherit;
    vertical-align: baseline;
  }
  /* HTML5 display-role reset for older browsers */
  article, aside, details, figcaption, figure, 
  footer, header, hgroup, menu, nav, section {
    display: block;
  }
  body {
    line-height: 1;
  }
  ol, ul {
    list-style: none;
  }
  blockquote, q {
    quotes: none;
  }
  blockquote:before, blockquote:after,
  q:before, q:after {
    content: '';
    content: none;
  }
  table {
    border-collapse: collapse;
    border-spacing: 0;
  }
  
  /*
    User CSS settings in PC
  */
  
  h1 {
    border-bottom:3px solid #EF9C99;
  }
  h2 {
    
  }
  h3 {
    
  }
  h4 {
    
  }
  h5 {
    
  }
  h6 {
    
  }
  p {
    
  }
  pre {
    
  }
  blockquote, q {
    
  }
  table {
    
  }
  tr {
    
  }
  th {
    
  }
  td {
    
  }
  a {
    
  }
  a:visited {
    
  }
  
  .container {
    
  }
  .header {
    
  }
  .main {
    
  }
  .entry-top {
    
  }
  .entry {
    
  }
  .entry-bottom {
    
  }
  .side {
    
  }
  .footer {
    
  }
  
/* Under 959px - SmartPhone and Tablet */
\@media screen and (max-width:959px) {

  /*
    User CSS settings in SmartPhone and Tablet
  */
  
  h1 {
    
  }
  h2 {
    
  }
  h3 {
    
  }
  h4 {
    
  }
  h5 {
    
  }
  h6 {
    
  }
  p {
    
  }
  pre {
    
  }
  blockquote, q {
    
  }
  table {
    
  }
  tr {
    
  }
  th {
    
  }
  td {
    
  }
  a {
    
  }
  a:visited {
    
  }
  
  .container {
    
  }
  .header {
    
  }
  .main {
    
  }
  .entry-top {
    
  }
  .entry {
    
  }
  .entry-bottom {
    
  }
  .side {
    
  }
  .footer {
    
  }
}
EOS

  return $common_css;
}

sub common_meta {
  my $meta =<<"EOS";
<!-- common/meta.tmpl.html -->
<meta charset="UTF-8">
EOS
  
  return $meta;
}

sub common_header {
  my $header =<<"EOS";
<!-- common/header.tmpl.html -->
EOS
  
  return $header;
}

sub common_footer {
  my $fotter =<<"EOS";
<!-- common/footer.tmpl.html -->
EOS
  
  return $fotter;
}

sub common_entry_top {
  my $entry_top =<<"EOS";
<!-- common/entry-top.tmpl.html -->
EOS
  
  return $entry_top;
}

sub common_entry_bottom {
  my $entry_bottom =<<"EOS";
<!-- common/entry-bottom.tmpl.html -->
EOS
  
  return $entry_bottom;
}

sub common_side {
  my $side =<<"EOS";
<!-- common/side.tmpl.html -->
EOS
  
  return $side;
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Giblog;

    my $foo = Giblog->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-giblog at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Giblog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Giblog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Giblog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Giblog>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Giblog>

=item * Search CPAN

L<https://metacpan.org/release/Giblog>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Giblog
