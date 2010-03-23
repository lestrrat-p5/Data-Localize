package Data::Localize::Format::Gettext;
use Any::Moose;

extends 'Data::Localize::Format';

no Any::Moose;

sub format {
    my ($self, $value, @args) = @_;
    $value =~ s/%(\d+)/ defined $args[$1 - 1] ? $args[$1 - 1] : '' /ge;
    $value =~ s|%(\w+)\(([^\)]+)\)|
        my $method = $1;
        my @embedded_args = split /,/, $2;
        my $code = $self->can($method);
        if (! $code) {
            Carp::confess(Scalar::Util::blessed($self) . " does not implement method '$method'");
        }
        $code->($self, \@args, \@embedded_args);
    |gex;

    return $value;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Data::Localize::Format::Gettext - Gettext Formatter

=head1 METHODS

=head2 format

=cut

