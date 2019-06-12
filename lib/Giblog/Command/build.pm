package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

use Carp 'confess';

sub run {
  confess "Not inplemented"
}

1;

=head1 名前

Giblog::Command::build - Webサイト構築コマンド

=head1 説明

L<Giblog::Command::build>はWebサイトを構築するためのコマンドです。

=head1 メソッド

L<Giblog::Command::build>はL<Giblog::Command>のすべてのメソッドを継承しており、次の新しいメソッドを実装しています。

=head2 run

  $command->run;

Webサイトを構築します。

このメソッドは、サブクラスでオーバーライドされることが予定されています。
