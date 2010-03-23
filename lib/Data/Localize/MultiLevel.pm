package Data::Localize::MultiLevel;
use Any::Moose;
use Config::Any;

with 'Data::Localize::Localizer',
    'Data::Localize::Trait::WithStorage' => {
        -exclude => [ qw(get_lexicon set_lexicon) ],
    },
;

no Any::Moose;

sub _build_formatter {
    Any::Moose::load_class('Data::Localize::Format::NamedArgs');
    return Data::Localize::Format::NamedArgs->new();
}

sub load_from_path {
    my ($self, $path) = @_;

    my @files = glob( $path );
    my $cfg = Config::Any->load_fiels({ files => \@files, use_ext => 1 });

    foreach my $x (@$cfg) {
        my ($filename, $lexicons) = %$x;
        # should have one root item
        my ($lang) = keys %$lexicons;

        $self->set_lexicon_map( $lang, $lexicons->{$lang} );
    }
}

sub get_lexicon {
    my ($self, $lang, $key) = @_;
    _rfetch( $self->lexicons->{$lang}, 0, [ split /\./, $key ] );
}

sub set_lexicon {
    my ($self, $lang, $key, $value) = @_;
    _rstore( $self->lexicons->{$lang}, 0, [ split /\./, $key ], $value );
}

sub _rfetch {
    my ($lexicon, $i, $keys) = @_;

    return unless $lexicon;

    my $thing = $lexicon->{$keys->[$i]};
    if (@$keys >= $i + 1) {
        return $thing;
    }

    if (ref $thing ne 'HASH') {
        if (Data::Localize::DEBUG()) {
            warn sprintf('%s does not point to a hash',
                join('.', map { $keys->[$_] } 0..$i)
            );
        }
        return ();
    }

    return _rfetch( $thing, $i + 1, $keys )
}

sub _rstore {
    my ($lexicon, $i, $keys, $value) = @_;

    return unless $lexicon;

    if (@$keys >= $i + 1) {
        $lexicon->{ $keys->[$i] } = $value;
        return;
    }

    my $thing = $lexicon->{$keys->[$i]};

    if (ref $thing ne 'HASH') {
        if (Data::Localize::DEBUG()) {
            warn sprintf('%s does not point to a hash',
                join('.', map { $keys->[$_] } 0..$i)
            );
        }
        return ();
    }

    return _rstore( $thing, $i + 1, $keys, $value );
}

1;

__END__

=head1 NAME

Data::Localize::MultiLevel - Fetch Data From Multi-Level Data Structures

=head1 SYNOPSIS

    use Data::Localize;

    my $loc = Data::Localize->new();

    $loc->add_localizer(
        Data::Localize::MultiLevel->new(
            path => [ ]
        )
    );

    $loc->localize( 'foo.key' );

    # above is internally... 
    $loc->localize_for(
        lang => 'en',
        id => 'foo.key',
    );
    # which in turn looks up...
    $lexicons->{foo}->{key};

=cut
