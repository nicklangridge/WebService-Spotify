package WebService::Spotify::OAuth2;
use Moose;
use MooseX::StrictConstructor;
use Method::Signatures;
use IO::File;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;
use MIME::Base64;

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
  my $token_info;
  if ($self->cache_path) {
    
    if (my $fh = IO::File->new('< ' . $self->cache_path)) {
      $token_info = from_json( $fh->read_lines );
      $fh->close;
    }

    $token_info = $self->refresh_access_token($token_info->{refresh_token}) if $self->is_token_expired($token_info);
  }
  return $token_info;
}

method save_token_info ($token_info) {
  if ($self->cache_path) {
    my $fh = IO::File->new('> ' . $self->cache_path) || die "Could not create cache file $@";
    print $fh to_json($token_info);
    $fh->close;
  }
}

method is_token_expired ($token_info) {
  my $now = time;
  return $token_info->{expires_at} < $now;
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
    code          => $code,
    redirect_uri  => $self->redirect_uri
  );
  $payload{scope} = $self->scope if $self->scope;
  $payload{state} = $self->state if $self->state;

  my $uri = URI->new( $self->oauth_token_url );
  $uri->query_param( $_, $payload{$_} ) for keys %payload;

  my $auth_header = encode_base64( $self>client_id . ':' . $self->client_secret );
  my %headers     = ( 'Authorization' => 'Basic ' . $auth_header );
  my $response    = $self->user_agent->post( $uri->as_string, %headers, Content => \%payload );

  die $response->status_line if $response->status_code != 200;
  
  my $token_info = from_json( $response->content );
  $self->save_token_info($token_info);

  return $token_info;
}

method refresh_access_token ($refresh_token) {
  my %payload = (
    grant_type    => 'refresh_token',
    refresh_token => $refresh_token
  );

  my $auth_header = encode_base64( $self>client_id . ':' . $self->client_secret );
  my %headers     = ( 'Authorization' => 'Basic ' . $auth_header );
  my $response    = $self->user_agent->post( $uri->as_string, %headers, Content => \%payload );

  die $response->status_line if $response->status_code != 200;

  my $token_info = from_json( $response->content );
  $token_info{expires_at} = time + $token_info{expires_in};
  $token_info{refresh_token} ||= $refresh_token;
  $self->save_token_info($token_info);

  return $token_info;
}

1;