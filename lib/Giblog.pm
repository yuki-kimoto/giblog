package Giblog;

use 5.008007;
use strict;
use warnings;

use Getopt::Long 'GetOptions';
use List::Util 'first';

=head1 NAME

Giblog - Static HTML Generator in Git and SmartPhone age

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, $class;
}

sub giblog_dir { shift->{'giblog_dir'} }
sub config { shift->{config} }

sub build_api {
  my ($class, %opt) = @_;
  
  my $giblog = Giblog->new(%opt);

  my $api = Giblog::API->new(giblog => $giblog);
  
  return $api;
}

sub parse_argv {
  my ($class, @argv) = @_;
  
  # Reorder command line args -x --xxx is after command
  my @ordered_argv;
  for my $arg (@argv) {
    if ($arg !~ /^-/) {
      push @ordered_argv, $arg;
    }
  }
  for my $arg (@argv) {
    if ($arg =~ /^-/) {
      push @ordered_argv, $arg;
    }
  }
  @argv = @ordered_argv;

  # Command
  my $command_name = shift @argv;
  unless (defined $command_name) {
    die "Command must be specifed\n";
  }
  if ($command_name =~ /^-/) {
    die "Command \"$command_name\" is not found\n";
  }
  
  local @ARGV = @argv;
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
  GetOptions(
    "d|giblog-dir=s" => \my $giblog_dir,
    'I|include=s'  => \my @include,
  );
  Getopt::Long::Configure($getopt_option_save);
  
  my $opt = {
    giblog_dir => $giblog_dir,
    include => \@include,
    command_name => $command_name,
    argv => \@argv
  };
  
  return $opt;
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
