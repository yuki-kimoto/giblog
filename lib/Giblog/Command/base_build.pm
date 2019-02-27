package Giblog::Command::base_build;

use base 'Giblog::Command';

use strict;
use warnings;
use File::Find 'find';
use Carp 'confess';
use File::Basename 'dirname';
use File::Path 'mkpath';
use Encode 'encode', 'decode';
use Giblog::Util;

sub run {
  my $self = shift;
}


1;
