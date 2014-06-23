package WebService::Spotify;
use strict;
use warnings;
use URI;
use JSON;
use LWP::UserAgent;

our $VERSION = '0.001';

sub new {
  my ($class, $args) = @_;
  
  return bless {
    api_root   => $args{api_root} || 'https://api.spotify.com/v1/',
    auth_token => $args{auth_token},
    user_agent => $args{user_agent}
  }, $class;
}

sub api_root   { return $_[0]->{api_root}   };
sub auth_token { return $_[0]->{auth_token} };

sub user_agent { 
  my $self = shift;
  
  $self->{user_agent} ||= LWP::UserAgent->new->(agent => 'WebService::Spotify/' . $VERSION);
  return $self->{user_agent};
};

sub get {
  my ($self, $method, $args) = @_;
  
  my $uri = URI->new( $self->api_root . $method );
  $uri->query_param( $_, $args{$_} ) for keys %$args;

  my $response = $self->user_agent->get( $uri->as_string );
  my $data     = from_json( $response->content );

  return $data;
}

1;

