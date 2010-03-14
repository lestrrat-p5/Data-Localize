use strict;
use lib "t/lib";
use utf8;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More tests => 16;
use Test::Data::Localize;

{
    my $tb = Test::Builder->new();
    binmode $_, ':utf8'
        for map { $tb->$_ } qw( output failure_output todo_output );
}

use_ok "Data::Localize";
use_ok "Data::Localize::Gettext";

{
    my $loc = Data::Localize::Gettext->new(
        path => 't/lib/Test/Data/Localize/Gettext/*.po'
    );

    is_deeply(
        $loc->paths,
        ['t/lib/Test/Data/Localize/Gettext/*.po'],
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
        path => 't/lib/Test/Data/Localize/Gettext/*.po'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!"});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->path_add($file);

    is_deeply(
        $loc->localizers->[0]->paths,
        [ 't/lib/Test/Data/Localize/Gettext/*.po', $file ],
        'paths contains newly added path'
    );

    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file});

}

SKIP: {
    eval "require BerkeleyDB";
    if ($@) {
        skip("Test requires BerkeleyDB", 2);
    }
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/lib/Test/Data/Localize/Gettext/*.po',
        storage_class => 'BerkeleyDB'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!" from BerkeleyDB file});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->path_add($file);
    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file after BerkeleyDB});

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
        path => 't/lib/Test/Data/Localize/Gettext/*.po'
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Dynamically Create Me!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔:a:b:cを動的に作成したぜ!', 'dynamic translation');
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a simple po file'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

msgid "I am empty"
msgstr ""
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a po file with an empty string for one id'
    );

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 1,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon, {
            'Hello, stranger!' => 'Bonjour, étranger!',
            'I am empty'       => q{},
        },
        'parsing a po file with an empty string for one id - keep_empty is true'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

#, fuzzy
msgid "I don't know"
msgstr "Je ne sais pas"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a po file with a fuzzy translation'
    );

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 1,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon, {
            'Hello, stranger!' => 'Bonjour, étranger!',
            q{I don't know}    => 'Je ne sais pas',
        },
        'parsing a po file with a fuzzy translation - use_fuzzy is true'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

msgid "One\n"
"Two \\ Three\n"
"Four"
msgstr "Un\n"
"Deux \\ Trois\n"
"Quatre"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!',
          "One\nTwo \\ Three\nFour" => "Un\nDeux \\ Trois\nQuatre",
        },
        'parsing a po file with a multi-line id and translation'
    );
}

sub write_po {
    my $po = shift;

    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'ja.po');
    open(my $fh, '>', $file) or die "Could not open $file: $!";

    binmode($fh, ':utf8');
    print $fh $po;
    close($fh);

    return $file;
}
