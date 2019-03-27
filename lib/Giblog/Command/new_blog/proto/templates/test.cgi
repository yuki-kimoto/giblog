#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Encode 'encode';

# Title mail form
my $title = 'Mail form';

# Content mail form
my $content = <<"EOS";
<h2>Title</h2>
<div>
  Content
</div>
EOS

$content = build_html($title, $content);

my $html = <<"EOS";
Content-type: text/html; charset=UTF-8

$content
EOS

print encode('UTF-8', $html);

sub build_html {
  my ($title, $content) = @_;
  
  local $/;
  my $html = <DATA>;
  
  $html =~ s/\$TITLE/$title/;
  $html =~ s/\$CONTENT/$content/;
  
  return $html;
}

__DATA__
