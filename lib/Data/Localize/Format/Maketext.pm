package Data::Localize::Format::Maketext;
use Any::Moose;

extends 'Data::Localize::Format';

no Any::Moose;

sub format {
    my ($self, $value, @args) = @_;

    $value =~ s|\[([^\]]+)\]|
        my @vars = split(/,/, $1);
        my $method;
        if ($vars[0] !~ /^_(-?\d+)$/) {
            $method = shift @vars;
        }

        ($method) ?
            $self->$method( map { (/^_(-?\d+)$/) ? $args[$1 - 1] : $_; } @args ) :
            @args[ map { (/^_(-?\d+)$/ ? $1 : $_) - 1 } @vars ];
    |gex;

    return $value;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Data::Localize::Format::Maketext - Maketext Formatter

=head1 METHODS

=head2 format

=cut
