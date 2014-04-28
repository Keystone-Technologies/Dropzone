package Mojolicious::Command::purge;
use Mojo::Base 'Mojolicious::Command';

use File::Spec::Functions qw(catdir catfile splitdir);

has description => 'abc';
has usage => 'xyz';

sub run {
  my $self = shift;
  
  my $path = catdir $self->app->home, 'public', 'uploads';
  opendir UPLOADS, $path;
  foreach ( grep { age($path, $_) } readdir(UPLOADS) ) {
    say
  }
}
              
sub age {
  my ($path, $_) = @_;
}

1;
