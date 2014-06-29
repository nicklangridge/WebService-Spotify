use strict;
use warnings;
use Data::Dumper;
use WebService::Spotify;
use Util;

my $username = $ARGV[0];

if (!$username) {
  print 'usage: perl user_playlists.pl <username>';
  exit;
}

my $token = Util::prompt_for_user_token($username);

if ($token) {
  my $sp = WebService::Spotify->new(auth => $token, trace => 0);
  my $playlists = $sp->user_playlists($username);
  print "$_->{name}\n" for @{ $playlists->{items} };
} else {
  print "Can't get token for $username\n";
}