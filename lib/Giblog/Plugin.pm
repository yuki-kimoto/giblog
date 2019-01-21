package Giblog::Plugin;

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, $class;
}

sub giblog { shift->{giblog} }

1;