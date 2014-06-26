package WebService::Spotify::OAuth2;
use Moose;
use MooseX::StrictConstructor;
use Method::Signatures;
use IO::File;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;

our $VERSION = '0.001';

has 'client_id'     => ( is => 'rw', isa => 'Str', required => 1 );
has 'client_secret' => ( is => 'rw', isa => 'Str', required => 1 );
has 'redirect_uri'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'state'         => ( is => 'rw', isa => 'Str' );
has 'scope'         => ( is => 'rw', isa => 'Str' );
has 'cache_path'    => ( is => 'rw', isa => 'Str' );

has 'oauth_authorize_url' => (
  is => 'rw',
  isa => 'Str',
  default => 'https://accounts.spotify.com/authorize'
);

has 'oauth_token_url' => (
  is => 'rw',
  isa => 'Str',
  default => 'https://accounts.spotify.com/api/token'
);

has 'user_agent' => (
  is => 'rw',
  isa => 'LWP::UserAgent',
  default => sub { 
    my $ua = LWP::UserAgent->new;
    $ua->agent("WebService::Spotify::OAuth2/$VERSION");
    return $ua;
  }
);

method get_cached_token {
  my $token;
  if ($self->cache_path) {
    
    if (my $fh = IO::File->new('< ' . $self->cache_path)) {
      $token = from_json( $fh->read_lines );
      $fh->close;
    }

    $token = $self->refresh_access_token($token->{refresh_token}) if $self->is_token_expired($token);
  }
  return $token;
}

method save_token_info ($token) {
  if ($self->cache_path) {
    my $fh = IO::File->new('> ' . $self->cache_path) || die "Could not create cache file $@";
    print $fh to_json($token);
    $fh->close;
  }
}

method is_token_expired ($token) {
  my $now = time;
  return $token->{expires_at} < $now;
}

method get_authorize_url {
  my %payload = (
    client_id     => $self->client_id,
    response_type => 'code',
    redirect_uri  => $self->redirect_uri
  );
  $payload{scope} = $self->scope if $self->scope;
  $payload{state} = $self->state if $self->state;

  my $uri = URI->new( $self->oauth_authorize_url );
  $uri->query_param( $_, $payload{$_} ) for keys %payload;

  return $uri->as_string;
}

method parse_response_code ($response) {
  return [split /&/, [split /?code=/, $response]->[1]]->[0];
}

method get_access_token ($code) {
  my %payload = (
    grant_type    => 'authorization_code',
    code          => 'code',
    redirect_uri  => $self->redirect_uri
  );
  $payload{scope} = $self->scope if $self->scope;
  $payload{state} = $self->state if $self->state;

  my $uri = URI->new( $self->oauth_token_url );
  $uri->query_param( $_, $payload{$_} ) for keys %payload;

  my $auth_header = base64.b64encode( $self>client_id . ':' . $self->client_secret );
  my %headers     = {'Authorization' => 'Basic ' . $auth_header};

  return $uri->as_string;
}


def get_access_token(self, code):
        payload = {'redirect_uri': self.redirect_uri,
                   'code': code,
                   'grant_type': 'authorization_code'}
        if self.scope:
            payload['scope'] = self.scope
        if self.state:
            payload['state'] = self.state

        auth_header = base64.b64encode(self.client_id + ':' + self.client_secret)
        headers = {'Authorization': 'Basic %s' % auth_header}


        response = requests.post(self.OAUTH_TOKEN_URL, data=payload, headers=headers, verify=True)
        if response.status_code is not 200:
            raise SpotifyOauthError(response.reason)
        token_info = response.json()
        token_info['expires_at'] = int(time.time()) + token_info['expires_in']
        self.save_token_info(token_info)
        return token_info

1;