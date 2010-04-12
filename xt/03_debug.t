use strict;
use Test::More;

local $ENV{DATA_LOCALIZE_DEBUG} = 1;

my @files = <t/*.t>;

while (my $file = shift @files) {
    subtest $file => sub { do $file };
}

done_testing();