use FindBin;
BEGIN {
  $ENV{MOJO_HOME} = "$FindBin::Bin/mysitezemi";
}

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
