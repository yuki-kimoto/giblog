package Giblog;

use 5.008007;
use strict;
use warnings;

use Getopt::Long 'GetOptions';

our $VERSION = '0.02';

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, $class;
}

sub home_dir { shift->{'home_dir'} }
sub config { shift->{config} }

sub build_api {
  my ($class, %opt) = @_;
  
  my $giblog = Giblog->new(%opt);

  my $api = Giblog::API->new(giblog => $giblog);
  
  return $api;
}

sub parse_argv {
  my ($class, @argv) = @_;
  
  # If first argument don't start with -, it is command
  my $command_name;
  if (@argv && $argv[0] !~ /^-/) {
    $command_name = shift @argv;
  }

  # Command
  unless (defined $command_name) {
    die "Command must be specifed\n";
  }
  if ($command_name =~ /^-/) {
    die "Command \"$command_name\" is not found\n";
  }
  
  local @ARGV = @argv;
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
  GetOptions(
    "h|home=s" => \my $home_dir,
    'I|include=s'  => \my @include,
  );
  Getopt::Long::Configure($getopt_option_save);
  
  my $opt = {
    home_dir => $home_dir,
    include => \@include,
    command_name => $command_name,
    argv => \@argv
  };
  
  return $opt;
}

=head1 NAME

Giblog - HTML Generator

=head1 DESCRIPTION

Giblog is HTML generator.

Giblog is in beta test before 1.0 release. Note that features is changed without warnings.

=head1 TUTORIAL
  
  # New web site
  giblog new mysite
  
  # Add new entry
  giblog add
  
  # Build web site
  giblog build

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
