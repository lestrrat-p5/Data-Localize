package Data::Localize::MultiLevel;
use Any::Moose;
use Config::Any;

with 'Data::Localize::Localizer',
    'Data::Localize::Trait::WithStorage' => {
        -exclude => [ qw(get_lexicon set_lexicon) ],
    },
;

has paths => (
    is => 'ro',
    isa => 'ArrayRef',
    trigger => sub {
        my $self = shift;
        $self->load_from_path($_) for @{$_[0]};
    },
);

no Any::Moose;

sub _build_formatter {
    Any::Moose::load_class('Data::Localize::Format::NamedArgs');
    return Data::Localize::Format::NamedArgs->new();
}

sub register {
    my ($self, $loc) = @_;
    $loc->add_localizer_map('*', $self);
}

sub load_from_path {
    my ($self, $path) = @_;

    my @files = glob( $path );
    my $cfg = Config::Any->load_files({ files => \@files, use_ext => 1 });

    foreach my $x (@$cfg) {
        my ($filename, $lexicons) = %$x;
        # should have one root item
        my ($lang) = keys %$lexicons;

        if (Data::Localize::DEBUG()) {
            printf STDERR ("[%s] Loaded %s for languages %s\n",
                Scalar::Util::blessed($self),
                $filename,
                $lang,
            );
        }
        $self->set_lexicon_map( $lang, $lexicons->{$lang} );
    }
}

sub get_lexicon {
    my ($self, $lang, $key) = @_;
    _rfetch( $self->get_lexicon_map($lang), 0, [ split /\./, $key ] );
}

sub set_lexicon {
    my ($self, $lang, $key, $value) = @_;
    _rstore( $self->get_lexicon_map($lang), 0, [ split /\./, $key ], $value );
}

sub _rfetch {
    my ($lexicon, $i, $keys) = @_;

    return unless $lexicon;

    my $thing = $lexicon->{$keys->[$i]};
    my $ref   = ref $thing;
    return unless $ref || length $thing;

    if (@$keys <= $i + 1) {
        return $thing;
    }

    if ($ref ne 'HASH') {
        if (Data::Localize::DEBUG()) {
            printf STDERR ("%s does not point to a hash\n",
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

    if (@$keys <= $i + 1) {
        $lexicon->{ $keys->[$i] } = $value;
        return;
    }

    my $thing = $lexicon->{$keys->[$i]};

    if (ref $thing ne 'HASH') {
        if (Data::Localize::DEBUG()) {
            printf STDERR ("%s does not point to a hash\n",
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
