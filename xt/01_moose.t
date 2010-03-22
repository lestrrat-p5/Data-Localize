use strict;
use Test::More;

local $ENV{ANY_MOOSE} = 'Moose';

my @files = <t/*.t>;
plan tests => scalar @files + 1;

while (my $file = shift @files) {
    subtest $file => sub { do $file };
}

ok( Any::Moose::moose_is_preferred() );