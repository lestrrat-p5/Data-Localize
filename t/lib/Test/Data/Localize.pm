# $Id: Localize.pm 31764 2009-04-01 01:16:45Z daisuke $

package Test::Data::Localize;

BEGIN {
    %ENV = 
        map { ($_ => $ENV{$_}) }
        grep { /^DATA_LOCALIZE/ || /^ANY_MOOSE/ }
        keys %ENV;
}

1;