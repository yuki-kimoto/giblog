package Giblog::Command::add;

use base 'Giblog::Command';

use strict;
use warnings;
use Carp 'confess';

sub run {
  my ($self) = @_;
  
  my $api = $self->api;
  
  my $entry_dir = $api->rel_file('templates/blog');
  
  # Data and time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  $year += 1900;
  $mon++;
  my $datetime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  
  # Create entry file
  my $entry_file = "$entry_dir/$datetime.html";
  if (-f $entry_file) {
    confess "Fail add command. $entry_file is Alread exists";
  }
  $api->create_file($entry_file);
  
  warn "Create $entry_file\n";
}

1;

=encoding utf8

=head1 名前

Giblog::Command::add - 新しいブログエントリーを追加するコマンド

=head1 説明

L<Giblog::Command::add>は、新しいブログエントリーを追加するためのコマンドです。

=head1 メソッド

L<Giblog::Command::add>はL<Giblog::Command>からすべてのメソッドを継承しており、次の新しいメソッドを実装しています。

=head2 run

  $command->run;

「templates/blog」ディレクトリの中に新しいブログエントリーページのファイルを作成します。

ファイルは、日付と時刻を含みます。

  templates/blog/20190416153053.html
