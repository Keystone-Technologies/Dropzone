package DZ;
use Mojo::Base -base;

use overload '""' => sub { shift->_uuid }, fallback => 1;

use Mojo::Log;
use Mojo::Path;
use Mojo::Util qw/slurp spurt/;

use List::Util qw/first/;
use UUID::Tiny ':std';
use File::Spec::Functions qw/catdir catfile/;

has uploads => 'public/uploads';
has app => sub { shift->{app} };
has log => sub { Mojo::Log->new };
has _uuid => sub {
  my $self = shift;
  local $_ = $self->app->param('uuid');
  if ( /^[0-9]+$/ ) {
    return $self->map($_);
  } elsif ( /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) {
    return $_;
  } else {
    $self->log->debug("How did this happen?!");
  }
  return undef;
};
has path => sub { Mojo::Path->new(catdir($_[0]->app->app->home, split('/', $_[0]->uploads), $_[0]->uuid)) };

sub new_uuid { uuid_to_string(create_uuid(UUID_V4)) }

sub index {
  my $self = shift;
  if ( my $index = shift ) {
    die unless $index =~ /^[0-9]+$/;
    return $self->map($self->_uuid($self->map($index)));
  } else {
    return $self->map($self->_uuid);
  }
}

sub uuid {
  my $self = shift;
  if ( my $uuid = shift ) {
    die unless $uuid =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
    return $self->_uuid($self->map($self->map($uuid)));
  } else {
    return $self->_uuid;
  }
}

sub map {
  my $self = shift;
  local $_ = shift;
  return undef unless defined $_;
  if ( /^[0-9]+$/ ) {
    my ($uuid, $index) = (undef, $_);
    if ( $self->app->session->{uuid}->[$index] ) { 
      $uuid = $self->app->session->{uuid}->[$index];
    } elsif ( $index == 0 || $index == -1 || $index == $#{$self->app->session->{uuid}}+1 ) {
      push @{$self->app->session->{uuid}}, $self->new_uuid;
      $uuid = $self->app->session->{uuid}->[$index];
    }
    #$self->log->debug("$index => $uuid");
    return $uuid;
  } elsif ( /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) {
    my ($uuid, $index) = ($_, undef);
    if ( grep { $uuid eq $_ } @{$self->app->session->{uuid}} ) {
      $index = first { $self->app->session->{uuid}->[$_] eq $uuid } 0 .. $#{$self->app->session->{uuid}};
    } else {
      push @{$self->app->session->{uuid}}, $uuid;
      $index = $#{$self->app->session->{uuid}};
    }
    #$self->log->debug("$uuid => $index");
    return $index;
  } else {
    $self->log->debug("How did this happen?!");
  }
  return undef;
}

sub name {
  my $self = shift;
  my $name = shift;
  my $file = catdir($self->path, '.dz-name');
  if ( $name ) {
    return spurt $name, $file if -w $file;
  }
  return -r $file ? slurp $file : undef;
};

sub file {
  my $self = shift;
  my $file = shift or return undef;
  return catfile($self->path, $file);
}

1;
