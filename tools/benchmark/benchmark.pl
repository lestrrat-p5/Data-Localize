package LM;
use base qw(Locale::Maketext);

package LM::en;
use base qw(LM);
our %Lexicon = (
    'Hello, [_1]' => 'Hello [_1]'
);

package DL::en;
our %Lexicon = (
    'Hello, [_1]' => 'Hello [_1]'
);

package main;
use strict;
use blib;
use Benchmark qw(cmpthese);
use Data::Localize;

my $loc = Data::Localize->new;
$loc->add_localizer(
    class => 'Namespace',
    namespaces => [ 'DL' ]
);
$loc->languages(['en']);

cmpthese(30_000, {
    locale_maketext => sub {
        my $handle = LM->get_handle('en');
        $handle->maketext('Hello, [_1]', 'John Doe');
    },
    data_localize => sub {
        $loc->localize('Hello, [_1]', 'John Doe');
    }
});
