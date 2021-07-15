use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Giblog need git command
{
  my $git_help = 'git --help';
  my $ret = system($git_help);
  if ($ret != 0) {
    warn "Giblog need git command\n";
    die "OS unsupported\n";
  }
}

# Giblog don't support Windows
{
  if ($^O eq 'Win32') {
    warn "Giblog does'nt support Windows\n";
    die "OS unsupported\n";
  }
}

WriteMakefile(
    NAME             => 'Giblog',
    AUTHOR           => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM     => 'lib/Giblog.pm',
    ABSTRACT_FROM    => 'lib/Giblog.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    EXE_FILES => ['script/giblog'],
    PREREQ_PM => {
      Mojolicious => '9.19'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Giblog-* t/tmp' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/giblog.git',
                web  => 'https://github.com/yuki-kimoto/giblog',
            },
        },
    },
);
