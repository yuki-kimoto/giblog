use strict;
use warnings;
use utf8;

use Giblog;
use Mojolicious::Lite;

# Build
Giblog->build;

# Mojolicious::Lite Application
my $app = app;

# Serve
Giblog->serve($app);
