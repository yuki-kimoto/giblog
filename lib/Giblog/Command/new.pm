package Giblog::Command::new;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @argv) = @_;
  
  my $website_name = shift @argv;

  my $api = $self->api;
  
  my $module_name = ref $self;
  
  $api->create_website_from_proto($website_name, $module_name);
}

1;

=encoding utf8

=head1 NAME

Giblog::Command::new - Empty website creating command

=head1 DESCRIPTION

L<Giblog::Command::new> is a command to create empty website.

You can also create your website creating command inheriting L<Giblog::Command::new> like L<Giblog::Command::new_blog> or L<Giblog::Command::new_website>.

=head1 METHODS

L<Giblog::Command::new> inherits all methods from L<Giblog::Command> and
implements the following new ones.

=head2 run

  $command->run($website_name);

Create website with website name.

All contents is copied from C<proto> directory.

C<proto> directory path is "/path/Giblog/Command/new/proto", if module loaded path is "/path/Giblog/Command/new.pm".
