package Data::Localize::Format::NamedArgs;
use Any::Moose;

extends 'Data::Localize::Format';

no Any::Moose;

sub format {
    my ($self, $value, $args) = @_;

    return $value unless ref $args eq 'HASH';

    $value =~ s/{{([^}]+)}}/ $args->{ $1 } || '' /ex;
    return $value;
}

__PACKAGE__->meta->make_immutable();

1;