package Data::Localize;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Any::Moose 'X::AttributeHelpers';
use I18N::LangTags ();
use I18N::LangTags::Detect ();

our $VERSION = '0.00008';
our $AUTHORITY = 'cpan:DMAKI';

BEGIN {
    if (! defined &DEBUG) {
        if ($ENV{DATA_LOCALIZE_DEBUG}) {
            *DEBUG = sub () { 1 };
        } else {
            *DEBUG = sub () { 0 };
        }
    }
}

has auto => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

has auto_style => (
    is => 'ro',
    isa => 'Str',
    default => 'maketext'
);

has auto_localizer => (
    is => 'ro',
    isa => 'Data::Localize::Auto',
    lazy_build => 1,
);

has languages => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    lazy_build => 1,
    provides => {
        push => 'add_languages',
    }
);

has fallback_languages => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    lazy_build => 1,
    provides => {
        push => 'add_fallback_languages',
    }
);

# Localizers are the actual minions that perform the localization.
# They must register themselves
subtype 'Data::Localize::LocalizerListArg'
    => as 'ArrayRef'
    => where {
        ! grep { ! blessed $_ || ! $_->does('Data::Localize::Localizer') } @$_;
    }
    => message {
        'localizers must be a list of Data::Localize::Localizer implementors'
    }
;
coerce 'Data::Localize::LocalizerListArg'
    => from 'ArrayRef[HashRef]'
    => via {
        my $ret = [ map {
            my $args  = $_;
            my $klass = delete $args->{class};
            if ($klass !~ s/^\+//) {
                $klass = "Data::Localize::$klass";
            }
            Any::Moose::load_class($klass);
            $klass->new(%$args);
        } @$_ ];
        return $ret;
    }
;

has localizers => (
    metaclass => 'Collection::Array',
    is => 'ro',
    isa => 'Data::Localize::LocalizerListArg',
    coerce => 1,
    default => sub { +[] },
    provides => {
        'push'  => 'push_localizers',
        'count' => 'count_localizers',
        'grep'  => 'grep_localizers',
    }
);

has localizer_map => (
    metaclass => 'Collection::Hash',
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
    provides => {
        get => 'get_localizer_from_lang',
        set => 'set_localizer_map',
    }
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Any::Moose '::Util::TypeConstraints';

sub BUILD {
    my $self = shift;
    if ($self->count_localizers > 0) {
        foreach my $loc (@{ $self->localizers }) {
            $loc->register($self);
        }
    }
    return $self;
}

sub _build_fallback_languages {
    return [];
}

sub _build_languages {
    my $self = shift;
    $self->detect_languages();
}

sub _build_auto_localizer {
    my $self = shift;
    require Data::Localize::Auto;
    Data::Localize::Auto->new( style => $self->auto_style );
}

sub detect_languages {
    my $self = shift;
    my @lang = I18N::LangTags::implicate_supers( 
        I18N::LangTags::Detect::detect() ||
        $self->fallback_languages,
    );
    if (&DEBUG) {
        print STDERR "[Data::Localize]: detect_languages auto-detected ", join(", ", map { "'$_'" } @lang ), "\n";
    }
    return wantarray ? @lang : \@lang;
}

sub detect_languages_from_header {
    my $self = shift;
    my @lang = I18N::LangTags::implicate_supers( 
        I18N::LangTags::Detect->http_accept_langs( $_[0] || $ENV{HTTP_ACCEPT_LANGUAGE}),
        $self->fallback_languages,
    );
    if (&DEBUG) {
        print STDERR "[Data::Localize]: detect_languages_from_header detected ", join(", ", map { "'$_'" } @lang ), "\n";
    }
    return wantarray ? @lang : \@lang;
}

sub set_languages {
    my $self = shift;
    $self->languages([ @_ > 0 ? @_ : $self->detect_languages ]);
}

sub localize {
    my ($self, $key, @args) = @_;

    foreach my $lang ($self->languages) {
        print STDERR "[Data::Localize]: localize - looking up $lang\n" if DEBUG;
        foreach my $localizer (@{$self->get_localizer_from_lang($lang) || []}) {
            my $out = $localizer->localize_for(
                lang => $lang,
                id => $key,
                args => \@args
            );
            return $out if $out;
        }
    }

    print STDERR "[Data::Localize]: localize - nothing found in registered languages\n" if DEBUG;

    # if we got here, we missed on all languages.
    # one last shot. try the '*' slot
    foreach my $localizer (@{$self->get_localizer_from_lang('*') || []}) {
        foreach my $lang ($self->languages) {
            if (DEBUG) {
                print STDERR "[Data::Localize]: localize - trying $lang for '*' with localizer $localizer\n" if DEBUG;
            }
            my $out = $localizer->localize_for(
                lang => $lang,
                id   => $key,
                args => \@args
            );
            if ($out) {
                print STDERR "[Data::Localize]: localize - found for $lang, adding to map\n" if DEBUG;
                # oh, found one? set it in the localizer map so we don't have
                # to look it up again
                $self->add_localizer_map($lang, $localizer);
                return $out;
            }
        }
    }

    # if you got here, and you /still/ can't find a proper localization,
    # then we fallback to 'auto' feature
    if ($self->auto) {
        if (DEBUG) {
            print STDERR "[Data::Localize]: localize - trying auto-lexicon for $key\n";
        }
        return $self->auto_localizer->localize_for(id => $key, args => \@args);
    }

    return ();
}

sub add_localizer {
    my $self = shift;

    my $localizer;
    if (@_ == 1) {
        $localizer = $_[1];
    } else {
        my %args = @_;
        my $klass = delete $args{class};
        if ($klass !~ s/^\+//) {
            $klass = "Data::Localize::$klass";
        }
        Any::Moose::load_class($klass);

        $localizer = $klass->new(%args);
    }

    $localizer->register($self);
    $self->push_localizers($localizer);
}

sub find_localizers {
    my ($self, %args) = @_;

    if (my $isa = $args{isa}) {
        return $self->grep_localizers(sub { $_[0]->isa($isa) });
    }
}

sub add_localizer_map {
    my ($self, $lang, $localizer) = @_;

    if (DEBUG) {
        print STDERR "[Data::Localize]: add_localizer_map $lang -> $localizer\n";
    }
    my $list = $self->get_localizer_from_lang($lang);
    if (! $list) {
        $list = [];
        $self->set_localizer_map($lang, $list);
    }
    unshift @$list, $localizer;
}

1;

__END__

=head1 NAME

Data::Localize - Alternate Data Localization API

=head1 SYNOPSIS

    use Data::Localize;

    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class     => "Namespace", # Locale::Maketext-style .pm files
        namespace => "MyApp::I18N"
    );

    $loc->add_localizer( 
        class => "Gettext",
        path  => "/path/to/localization/data/*.po"
    );

    $loc->set_languages();
    # or explicitly set one
    # $loc->set_languages('en', 'ja' );

    # looks under $self->languages, and checks if there are any
    # localizers that can handle the job
    $loc->localize( 'Hellow, [_1]!', 'John Doe' );

    # You can enable "auto", which will be your last resort fallback.
    # The key you give to the localize method will be used as the lexicon
    $self->auto(1);

=head1 DESCRIPTION

Data::Localize is an object oriented approach to localization, aimed to
be an alternate choice for Locale::Maketext, Locale::Maketext::Lexicon, and
Locale::Maketext::Simple.

=head1 BASIC WORKING 

=head2 STRUCTURE

Data::Localize is a wrapper around various Data::Localize::Localizer 
implementors (localizers). So if you don't specify any localizers, 
Data::Localize will do... nothing (unless you specify C<auto>).

Localizers are the objects that do the actual localization. Localizers must
register themselves to the Data::Localize parent, noting which languages it
can handle (which usually is determined by the presence of data files like
en.po, ja.po, etc). A special language ID of '*' is used to accept fallback
cases. Localizers registered to handle '*' will be tried I<after> all other
language possibilities have been exhausted.

If the particular localizer cannot deal with the requested string, then
it simply returns nothing.

=head2 AUTO-GENERATING LEXICONS

Locale::Maketext allows you to supply an "_AUTO" key in the lexicon hash,
which allows you to pass a non-existing key to the localize() method, and
use it as the actual lexicon, if no other applicable lexicons exists.

    # here, we're deliberately not setting any localizers
    my $loc = Data::Localize->new(auto => 1);

    print $loc->localize('Hello, [_1]', 'John Doe'), "\n";

Locale::Maketext attaches this to the lexicon hash itself, but Data::Localizer
differs in that it attaches to the Data::Localizer object itself, so you
don't have to place _AUTO everwhere.

=head1 UTF8

All data is expected to be in decoded utf8. You must "use utf8" for all values
passed to Data::Localizer. We won't try to be smart for you. USE UTF8!

=head1 USING ALTERNATE STORAGE

By default all lexicons are stored on memory, but if you're building an app
with thousands and thousands of long messages, this might not be the ideal
solution. In such cases, you can change where the lexicons get stored

    my $loc = Data::Localize->new();
    $loc->add_namespace(
        class         => 'Gettext',
        path          => '/path/to/data/*.po'
        storage_class => 'BerkeleyDB',
        storage_args  => {
            dir => '/path/to/really/fast/device'
        }
    );

This would cause Data::Localize to put all the lexicon data in several BerkeleyDB files under /path/to/really/fast/device

Note that this approach would buy you no gain if you use Data::Localize::Namespace, as that approach by default expects everything to be in memory.

=head1 DEBUGGING

=head2 DEBUG

To enable debug tracing, either set DATA_LOCALIZE_DEBUG environment variable,

    DATA_LOCALIZE_DEBUG=1 ./yourscript.pl

or explicitly define a function before loading Data::Localize:

    BEGIN {
        *Data::Localize::DEBUG = sub () { 1 };
    }
    use Data::Localize;

=head1 METHODS

=head2 add_localizer

Adds a new localizer. You may either pass a localizer object, or arguments
to your localizer's constructor:

    $loc->add_localizer( YourLocalizer->new );

    $loc->add_localizer(
        class => "Namespace",
        namespaces => [ 'Blah' ]
    );

=head2 localize

Localize the given string ID, using provided variables.

    $localized_string = $loc->localize( $id, @args );

=head2 detect_languages

Detects the current set of languages to use. If used in an CGI environment,
will attempt to detect the language of choice from headers. See
I18N::LanguageTags::Detect for details.

=head2 detect_languages_from_header 

Detects the language from the given header value, or from HTTP_ACCEPT_LANGUAGES environment variable

=head2 add_localizer_map

Used internally.

=head2 find_localizers 

Finds a localizer by its attribute. Currently only supports isa

    my @locs = $loc->find_localizers(isa => 'Data::Localize::Gettext');

=head2 set_languages

If used without any arguments, calls detect_languages() and sets the
current language set to the result of detect_languages().

=head1 TODO

Gettext style localization files -- Make it possible to decode them
Check performance -- see benchmark/benchmark.pl

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT

=over 4

=item The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=back

=cut