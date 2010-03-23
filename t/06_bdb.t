use strict;
use utf8;
use Test::More tests => 3;
use Test::Requires;
use t::Data::Localize::Test qw(write_po);

test_requires 'BerkeleyDB';

use_ok "Data::Localize";
{
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/04_gettext/*.po',
        storage_class => 'BerkeleyDB'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!" from BerkeleyDB file});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->add_path($file);
    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file after BerkeleyDB});

}

