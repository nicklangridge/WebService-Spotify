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
  default => sub { 
    my $ua = LWP::UserAgent->new;
    $ua->agent("WebService::Spotify/$VERSION");
    return $ua;
  }
);

method _auth_headers {
  return $self->auth ? { 'Authorization' =>  'Bearer ' . $self->auth } : undef;
}

method _uri($method, %args) {
  my $base_uri = $method =~ /^http/ ? $method : $self->prefix . $method;

  my $uri = URI->new( $base_uri );
  $uri->query_param( $_, $args{$_} ) for keys %args;

  return $uri;
}

method get ($method, %args) {
  my $uri      = $self->_uri( $method, %args );
  my $headers  = $self->_auth_headers;
  my $response = $self->user_agent->get( $uri->as_string, %$headers );
  my $data     = from_json( $response->content );

  ## TODO: exception handing

  return $data;
}

method post ($method, $payload, %args) {
  my $uri      = $self->_uri( $method, %args );
  my $headers  = $self->_auth_headers;
  $headers->{'Content-Type'} = 'application/json';
  my $response = $self->user_agent->post( $uri->as_string, %$headers, Content => to_json($payload) );
  my $data     = from_json( $response->content );

  ## TODO: exception handing
  
  return $data;
}

method next ($result) {
   return $self->get($result->{next}) if $result->{next};
}

method previous ($result) {
   return $self->get($result->{previous}) if $result->{previous};
}

method track ($track) {
  my $track_id = $self->_get_id('track', $track);
  return $self->get("tracks/$track_id");
}

method tracks ($tracks) {  
  my @track_ids = map { $self->_get_id('track', $_) } @$tracks;
  return $self->get('tracks/?ids=' . join(',', @track_ids));
}

method artist ($artist) {
  my $artist_id = $self->_get_id('artist', $artist);
  return $self->get("artists/$artist_id");
}

method artists ($artists) {  
  my @artist_ids = map { $self->_get_id('artist', $_) } @$artists;
  return $self->get('artists/?ids=' . join(',', @artist_ids));
}

method artist_albums ($artist, :$album_type, :$country, :$limit = 20, :$offset = 0) {
  my $artist_id = $self->_get_id('artist', $artist);
  return $self->get("artists/$artist_id/albums", album_type => $album_type, country => $country, limit => $limit, offset => $offset);
}

method artist_top_tracks ($artist, :$country = 'US') {
  my $artist_id = $self->_get_id('artist', $artist);
  return $self->get("artists/$artist_id/top-tracks", country => $country);
}

method album ($album) {
  my $album_id = $self->_get_id('album', $album);
  return $self->get("albums/$album_id");
}

method album_tracks ($album) {
  my $album_id = $self->_get_id('album', $album);
  return $self->get("albums/$album_id/tracks");
}

method albums ($albums) {
  my @album_ids = map { $self->_get_id('album', $_) } @$albums;
  return $self->get('albums/?ids=' . join(',', @album_ids));
}

method search ($q, :$limit = 10, :$offset = 0, :$type = 'track') {
  return $self->get('search', q => $q, limit => $limit, offset => $offset, type => $type);
}

method user ($q, $user_id) {
  return $self->get("users/$user_id");
}

method user_playlists($user_id) {
  return $self->get("users/$user_id/playlists");
}

method user_playlist($user_id, :$playlist_id, :$fields) {
  my $method = $playlist_id ? "playlists/$playlist_id" : "starred";
  return $self->get("users/$user_id/$method", $fields => $fields);
}

method user_playlist_create($user_id, $name, :$public = 1) {
  my $data = { 'name' => $name, 'public' => $public };
  return $self->post("users/$user_id/playlists", $data);
}

method user_playlist_add_tracks($user_id, $playlist_id, $tracks, :$position) {
  return $self->post("users/$user_id/playlists/$playlist_id/tracks", $tracks, $position => $position);
}

method me ($user_id, $playlist_id, $tracks, :$position) {
  return $self->get('me/');
}

method _get_id ($type, $id) {
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

