use strict;
use lib "t/lib";
use utf8;
use Test::More tests => 8;
use File::Spec;
use t::Data::Localize::Test qw(write_po);

use_ok "Data::Localize";
use_ok "Data::Localize::Gettext";

{
    my $loc = Data::Localize::Gettext->new(
        path => 't/04_gettext/*.po',
    );

    is_deeply(
        $loc->paths,
        [ 't/04_gettext/*.po' ],
        'paths contains single glob value in t/lib - BUILDARGS handles path argument correctly'
    );

    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!"});
}

{
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/04_gettext/*.po'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!"});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->add_path($file);

    is_deeply(
        $loc->localizers->[0]->paths,
        [ 't/04_gettext/*.po', $file ],
        'paths contains newly added path'
    );

    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file});

}

{
    my $class = Data::Localize::Gettext->meta->create_anon_class(
        superclasses => [ 'Data::Localize::Gettext' ],
        methods      => {
            test => sub {
                my ($self, $args, $embedded) = @_;
                return join(':', @$args, @$embedded);
            }
        }
    );
    my $loc = $class->name->new(
        path => 't/04_gettext/*.po'
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Dynamically Create Me!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔:a:b:cを動的に作成したぜ!', 'dynamic translation');
}

