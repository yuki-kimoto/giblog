use 5.008007;
use strict;
use warnings;
use ExtUtils::MakeMaker;

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
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Giblog-*' },
);
