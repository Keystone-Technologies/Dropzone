package DZ;
use Mojo::Base -base;

use overload '""' => sub { shift->uuid }, fallback => 1;

use Mojo::Log;
use Mojo::Path;

use UUID::Tiny ':std';
use File::Spec::Functions qw/catdir catfile/;

has uploads => 'public/uploads';
has app => sub { shift->{app} };
has log => sub { Mojo::Log->new };
has _index => sub { shift->app->param('index') };
has _uuid => sub { shift->app->param('uuid') };
has path => sub { Mojo::Path->new(catdir($_[0]->app->app->home, split('/', $_[0]->uploads), $_[0]->uuid)) };

sub new_uuid { uuid_to_string(create_uuid(UUID_V4)) }

#$self->app->log->debug($self->dz->index.' => '.$self->dz->uuid);
sub index {
  my $self = shift;
  $self->app->session->{uuid} = [$self->app->session->{uuid}] if ! ref $self->app->session->{uuid};
  return $self->_index if $self->_index && !@_;
  local $_ = shift || $self->_index || $self->_uuid or return $self->_uuid($self->new_uuid);
  if ( /^[0-9]+$/ ) {
    if ( $self->app->session->{uuid}->[$_] ) { 
      return $self->_uuid($self->app->session->{uuid}->[$_]);
    } elsif ( $_ == 0 ) {
      push @{$self->app->session->{uuid}}, $self->new_uuid;
      return $self->_uuid($self->app->session->{uuid}->[-1]);
    } else {
      return undef;
    }
  } elsif ( /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) {
    my $uuid = $_;
    if ( grep { $uuid eq $_ } @{$self->app->session->{uuid}} ) {
      $self->_uuid($uuid);
      return first { $self->app->session->{uuid}->[$_] eq $uuid } 0 .. $#{$self->app->session->{uuid}};
    } else {
      push @{$self->app->session->{uuid}}, $self->_uuid($uuid);
      return $#{$self->app->session->{uuid}};
    }
  }
}

sub uuid {
  my $self = shift;
  $self->app->session->{uuid} = [$self->app->session->{uuid}] if ! ref $self->app->session->{uuid};
  return $self->_uuid if $self->_uuid && !@_;
  local $_ = shift || $self->_index || $self->_uuid or return $self->_uuid($self->new_uuid);
  if ( /^[0-9]+$/ ) {
    if ( $self->app->session->{uuid}->[$_] ) { 
      return $self->_uuid($self->app->session->{uuid}->[$_]);
    } elsif ( $_ == 0 ) {
      push @{$self->app->session->{uuid}}, $self->new_uuid;
      return $self->_uuid($self->app->session->{uuid}->[-1]);
    } else {
      return undef;
    }
  } elsif ( /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) {
    my $uuid = $_;
    if ( grep { $uuid eq $_ } @{$self->app->session->{uuid}} ) {
      $self->_uuid($uuid);
      return first { $self->app->session->{uuid}->[$_] eq $uuid } 0 .. $#{$self->app->session->{uuid}};
    } else {
      push @{$self->app->session->{uuid}}, $self->_uuid($uuid);
      return $#{$self->app->session->{uuid}};
    }
  }
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
