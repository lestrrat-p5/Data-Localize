package BadLocalizer;
use Any::Moose;
extends 'Data::Localize::Localizer';

package BadFormatter;
use Any::Moose;
extends 'Data::Localize::Format';

package main;
use strict;
use Test::More tests => 2;
use Data::Localize;

{
    my $loc = Data::Localize->new();
    eval {
        $loc->add_localizer( '+BadLocalizer' );
    };
    like( $@, qr/Bad localizer/ );
}

{
    my $format = BadFormatter->new();
    eval {
        $format->format;
    };
    like( $@, qr/format\(\) must be overridden/ );
}


## should be more
