use strict;
use lib "t/lib";
use utf8;
use Test::More tests => 6;
use Test::Data::Localize;

use_ok "Data::Localize";
use_ok "Data::Localize::Namespace";

{
    my $loc = Data::Localize::Namespace->new(
        namespaces => [ 'Test::Data::Localize::Namespace' ]
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', "localization for ja");
}

{
    # hack
    no warnings 'once';
    local $Test::Data::Localize::Namespace::ja::Lexicon{'Hello, [_1]!'} = '[_1]さん、こんにちは!';
    my $loc = Data::Localize::Namespace->new(
        style => 'maketext',
        namespaces => [ 'Test::Data::Localize::Namespace' ]
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', "localization with additional lexicon");
}

{
    my $loc = Data::Localize->new(languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Namespace',
        namespaces => [ 'Test::Data::Localize::Namespace' ]
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', "localization for ja");

    $loc->localizers->[0]->add_namespaces(
        'Test::Data::Localize::AltNamespace'
    );

    $out = $loc->localize('Good night, stranger!', '牧大輔');
    is($out, '牧大輔さん、おやすみなさい!', "localization after adding extra");

}
