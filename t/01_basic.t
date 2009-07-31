use strict;
use lib "t/lib";
use Test::More (tests => 2);
use Test::Data::Localize;

use_ok "Data::Localize";

my $loc = Data::Localize->new(
    auto => 0,
    fallback_languages => [ 'en' ],
);
$loc->add_localizer(
    class => 'Namespace',
    namespaces => [ 'Test::Data::Localize::Namespace' ]
);

is($loc->localize("Hello, stranger!", "John Doe"), "Hello, John Doe!");