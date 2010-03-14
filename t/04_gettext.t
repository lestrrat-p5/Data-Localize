use strict;
use lib "t/lib";
use utf8;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More tests => 8;
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
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!');
}

{
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/lib/Test/Data/Localize/Gettext/*.po'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!');

    # Generate a new po file so that we can add it to the path list
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'ja.po');
    open(my $fh, '>', $file) or die "Could not open $file: $!";

    binmode($fh, ':utf8');
    print $fh <<EOM;
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM
    close($fh);

    $loc->localizers->[0]->path_add($file);
    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！');

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
    is($out, '牧大輔さん、こんにちは!');

    # Generate a new po file so that we can add it to the path list
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'ja.po');
    open(my $fh, '>', $file) or die "Could not open $file: $!";

    binmode($fh, ':utf8');
    print $fh <<EOM;
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM
    close($fh);

    $loc->localizers->[0]->path_add($file);
    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！');

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
    is($out, '牧大輔:a:b:cを動的に作成したぜ!');
}