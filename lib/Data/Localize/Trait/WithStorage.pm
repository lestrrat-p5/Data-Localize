package Data::Localize::Trait::WithStorage;
use Any::Moose '::Role';
use File::Temp ();
use Data::Localize::Util qw(_alias_and_deprecate);

has storage_class => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        return '+Data::Localize::Storage::Hash';
    }
);

has storage_args => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has lexicon_map => (
    is => 'ro',
    isa => 'HashRef[Data::Localize::Storage]',
    default => sub { +{} },
);

no Any::Moose;

sub get_lexicon_map {
    my ($self, $key) = @_;
    return $self->lexicon_map->{ $key };
}

sub set_lexicon_map {
    my ($self, $key, $value) = @_;
    return $self->lexicon_map->{ $key } = $value;
}

sub get_lexicon {
    my ($self, $lang, $id) = @_;
    my $lexicon = $self->get_lexicon_map($lang);
    return () unless $lexicon;
    $lexicon->get($id);
}

sub set_lexicon {
    my ($self, $lang, $id, $value) = @_;
    my $lexicon = $self->get_lexicon_map($lang);
    if (! $lexicon) {
        $lexicon = $self->_build_storage($lang);
        $self->set_lexicon_map($lang, $lexicon);
    }
    $lexicon->set($id, $value);
}

sub merge_lexicon {
    my ($self, $lang, $new_lexicon) = @_;

    my $lexicon = $self->get_lexicon_map($lang);
    if (! $lexicon) {
        $lexicon = $self->_build_storage($lang);
        $self->set_lexicon_map($lang, $lexicon);
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
        my $dir  = ($args->{dir} ||= File::Temp::tempdir(CLEANUP => 1));
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

_alias_and_deprecate lexicon_get => 'get_lexicon';
_alias_and_deprecate lexicon_set => 'set_lexicon';
_alias_and_deprecate lexicon_map_get => 'get_lexicon_map';
_alias_and_deprecate lexicon_map_set => 'set_lexicon_map';
_alias_and_deprecate lexicon_merge => 'merge_lexicon';

1;

__END__

=head1 NAME

Data::Localize::Trait::WithStorage - Localizer With Configurable Storage

=head1 METHODS

=head2 get_lexicon($lang, $id)

Gets the specified lexicon

=head2 set_lexicon($lang, $id, $value)

Sets the specified lexicon

=head2 merge_lexicon

Merges lexicon (may change...)

=head2 get_lexicon_map($lang)

Get the lexicon map for language $lang

=head2 set_lexicon_map($lang, \%lexicons)

Set the lexicon map for language $lang

=cut
