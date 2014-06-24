package WebService::Spotify;
use Moose;
use MooseX::StrictConstructor;
use Method::Signatures;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;

our $VERSION = '0.001';

has 'prefix' => (
  is => 'rw',
  isa => 'Str',
  default => 'https://api.spotify.com/v1/'
);

has 'auth' => (
  is => 'rw',
  isa => 'Str',
);

has 'user_agent' => (
  is => 'rw',
  isa => 'LWP::UserAgent',
  required => 0,
  default => method { LWP::UserAgent->new->(agent => 'WebService::Spotify/' . $VERSION) }
);

method get ($method, $args) {
  my $uri = URI->new( $self->prefix . $method );
  $uri->query_param( $_, $args{$_} ) for keys %$args;

  my $response = $self->user_agent->get( $uri->as_string );
  my $data     = from_json( $response->content );

  return $data;
}

method next ($result) {
   return $self.get($result{next}) if $result{next};
}

method previous ($result) {
   return $self.get($result{previous}) if $result{previous};
}

method track ($track) {
  my $track_id = $self._get_id('track', $track);
  return $self.get('tracks/' . $track_id);
}

method tracks (@tracks) {  
  my @track_ids = map { $self._get_id('track', $_) } @tracks;
  return $self.get('tracks/?ids=' . join(',', @track_ids));
}

method artist ($artist) {
  my $artist_id = $self._get_id('artist', $artist);
  return $self.get('artists/' . $artist_id);
}

method artists ($artists) {  
  my @artist_ids = map { $self._get_id('artist', $_) } @artists;
  return $self.get('artists/?ids=' . join(',', @artist_ids));
}

method artist_albums ($artist, :$album_type, :$country, :$limit = 20, :$offset = 0) {
  my $artist_id = $self._get_id('artist', $artist);
  return self.get('artists/' . $artist_id . '/albums', { album_type => $album_type, country => $country, limit => $limit, offset => $offset })
}

method _get_id {
  my ($self, $type, $id) = @_;

  my @fields = split /:/, $id;
  if (@fields == 3) {
    warn "expected id of type $type but found type $fields[2] id" if $type ne $fields[1];
    return $fields[2];
  }

  @fields = split /\//, $id;
  if (@fields >= 3) {
    warn "expected id of type $type but found type $fields[-2] id" if $type ne $fields[-2];
    return $fields[-1];
  }

  return $id;
}

1;

