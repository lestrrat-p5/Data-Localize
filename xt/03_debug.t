use strict;
use Test::More;
use File::Spec;

local $ENV{DATA_LOCALIZE_DEBUG} = 1;

open(*STDERR, '>', File::Spec->devnull) 
    or die "Failed to open " . File->Spec->devnull;

my @files = <t/*.t>;

while (my $file = shift @files) {
    subtest $file => sub { do $file };
}

done_testing();