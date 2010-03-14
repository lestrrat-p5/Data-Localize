
package Data::Localize::Gettext;
use utf8;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use Data::Localize::Gettext::Parser;
use File::Basename ();
use File::Spec;
use File::Temp qw(tempdir);
use Data::Localize::Storage::Hash;

with 'Data::Localize::Localizer';

has 'encoding' => (
    is => 'rw',
    isa => 'Str',
    default => 'utf-8',
);

has 'paths' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    trigger => sub {
        my $self = shift;
        $self->load_from_path($_) for @{$_[0]};
    },
    provides => {
        push => 'path_add',
    }
);

after 'path_add' => sub {
    my $self = shift;
    $self->load_from_path($_) for @_;
};

has 'storage_class' => (
    is => 'rw',
    isa => 'Str',
    default => sub {
        return '+Data::Localize::Storage::Hash';
    }
);

has 'storage_args' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

has 'lexicon_map' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef[Data::Localize::Storage]',
    default => sub { +{} },
    provides => {
        get => 'lexicon_map_get',
        set => 'lexicon_map_set'
    }
);

has 'use_fuzzy' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has 'allow_empty' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub BUILDARGS {
    my ($class, %args) = @_;

    my $path = delete $args{path};
    if ($path) {
        $args{paths} ||= [];
        push @{$args{paths}}, $path;
    }
    $class->SUPER::BUILDARGS(%args, style => 'gettext');
}

sub register {
    my ($self, $loc) = @_;
    $loc->add_localizer_map('*', $self);

}

sub load_from_path {
    my ($self, $path) = @_;

    return unless $path;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_path - loading from glob($path)\n" 
    }

    foreach my $x (glob($path)) {
        $self->load_from_file($x) if -f $x;
    }
}

sub load_from_file {
    my ($self, $file) = @_;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_file - loading from file $file\n"
    }

    my $parser = Data::Localize::Gettext::Parser->new(
        use_fuzzy  => $self->use_fuzzy(),
        keep_empty => $self->allow_empty(),
        encoding   => $self->encoding(),
    );

    my $lexicon = $parser->parse_file($file);

    my $lang = File::Basename::basename($file);
    $lang =~ s/\.[mp]o$//;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_file - registering ",
            scalar keys %{$lexicon}, " keys\n"
    }

    # This needs to be merged
    $self->lexicon_merge($lang, $lexicon);
}

sub format_string {
    my ($self, $value, @args) = @_;
    $value =~ s/%(\d+)/ defined $args[$1 - 1] ? $args[$1 - 1] : '' /ge;
    $value =~ s/%(\w+)\(([^\)]+)\)/
        $self->_method( $1, $2, \@args )
    /gex;

    return $value;
}

sub _method {
    my ($self, $method, $embedded, $args) = @_;

    my @embedded_args = split /,/, $embedded;
    my $code = $self->can($method);
    if (! $code) {
        confess(blessed $self . " does not implement method $method");
    }
    return $code->($self, $args, \@embedded_args );
}

sub lexicon_get {
    my ($self, $lang, $id) = @_;
    my $lexicon = $self->lexicon_map_get($lang);
    return () unless $lexicon;
    $lexicon->get($id);
}

sub lexicon_set {
    my ($self, $lang, $id, $value) = @_;
    my $lexicon = $self->lexicon_map_get($lang);
    if (! $lexicon) {
        $lexicon = $self->build_storage();
        $self->lexicon_map_set($lang, $lexicon);
    }
    $lexicon->set($id, $value);
}

sub lexicon_merge {
    my ($self, $lang, $new_lexicon) = @_;

    my $lexicon = $self->lexicon_map_get($lang);
    if (! $lexicon) {
        $lexicon = $self->_build_storage($lang);
        $self->lexicon_map_set($lang, $lexicon);
    }
    while (my ($key, $value) = each %$new_lexicon) {
        $lexicon->set($key, $value);
    }
}

sub _build_storage {
    my ($self, $lang) = @_;

    my $class = $self->storage_class;
    my $args  = $self->storage_args;
    my %args;

    if ($class !~ s/^\+//) {
        $class = "Data::Localize::Storage::$class";
    }
    Any::Moose::load_class($class);

    if ( $class->isa('Data::Localize::Storage::BerkeleyDB') ) {
        my $dir  = ($args->{dir} ||= tempdir(CLEANUP => 1));
        return $class->new(
            bdb_class => 'Hash',
            bdb_args  => {
                -Filename => File::Spec->catfile($dir, $lang),
                -Flags    => BerkeleyDB::DB_CREATE(),
            }
        );
    } else {
        return $class->new();
    }
}

1;

__END__

=head1 NAME

Data::Localize::Gettext - Acquire Lexicons From .po Files

=head1 DESCRIPTION

=head1 METHODS

=head2 lexicon_get($lang, $id)

Gets the specified lexicon

=head2 lexicon_set($lang, $id, $value)

Sets the specified lexicon

=head2 lexicon_merge

Merges lexicon (may change...)

=head2 load_from_file

Loads lexicons from specified file

=head2 load_from_path

Loads lexicons from specified path. May contain glob()'able expressions.

=head2 register

Registeres this localizer

=head2 parse_metadata

Parse meta data information in .po file

=head1 UTF8 

Currently, strings are assumed to be utf-8,

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Parts of this code stolen from Locale::Maketext::Lexicon::Gettext.

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
