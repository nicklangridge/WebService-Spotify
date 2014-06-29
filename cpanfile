requires 'Moo';
requires 'Method::Signatures';
requires 'LWP::UserAgent';
requires 'URI::QueryParam';
requires 'JSON';
requires 'Data::Dumper';
requires 'IO::File';
requires 'MIME::Base64';

on 'test' => sub {
  requires 'Test::Most';
};