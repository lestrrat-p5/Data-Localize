package Data::Localize::Format::Gettext;
use Any::Moose;

extends 'Data::Localize::Format';

no Any::Moose;

sub format {
    my ($self, $lang, $value, @args) = @_;

    $value =~ s|%(\w+)\(([^\)]+)\)| $self->_call_method( $lang, $1, $2, \@args ) |gex;
    $value =~ s/%(\d+)/ defined $args[$1 - 1] ? $args[$1 - 1] : '' /ge;

    return $value;
}

sub _call_method {
    my ($self, $lang, $method, $embedded, $args) = @_;

    my $code = $self->can($method);
    if (! $code) {
        Carp::confess(Scalar::Util::blessed($self) . " does not implement method '$method'");
    }

    my @embedded_args = split /,/, $embedded;
    for (@embedded_args) {
        if ( $_ =~ /%(\d+)/ ) {
            $_ = $args->[ $1 - 1 ];
        }
    }

    return $code->($self, $lang, \@embedded_args);
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Data::Localize::Format::Gettext - Gettext Formatter

=head1 METHODS

=head2 format

=cut

