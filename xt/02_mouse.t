use strict;
use Test::More;

local $ENV{ANY_MOOSE} = 'Mouse';

my @files = <t/*.t>;
plan tests => scalar @files + 1;

while (my $file = shift @files) {
    subtest $file => sub { do $file };
}

ok( Any::Moose::mouse_is_preferred() );

