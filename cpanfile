requires 'Moo';
requires 'Method::Signatures';
requires 'LWP::UserAgent';
requires 'URI::QueryParam';
requires 'JSON';

on 'test' => sub {
  requires 'Test::Most';
};