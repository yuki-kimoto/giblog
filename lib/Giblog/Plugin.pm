package Giblog::Plugin;

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, $class;
}

sub giblog {
  return $self->{giblog};
}

1;