package Giblog::Command;

sub new {
  my $class = shift;
  
  my $self = {@_};
  
  return bless $self, $class;
}

sub api { shift->{api} }

1;