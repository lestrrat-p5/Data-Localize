package Data::Localize::Format::NamedArgs;
use Any::Moose;

extends 'Data::Localize::Format';

no Any::Moose;

sub format {
    my ($self, $lang, $value, $args) = @_;

    return $value unless ref $args eq 'HASH';

    $value =~ s/{{([^}]+)}}/ $args->{ $1 } || '' /ex;
    return $value;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Data::Localize::Format::NamedArgs - Process Lexicons With Named Args

=head1 SYNOPSIS

    # "Hello {{name}}" -> "Hello, John"
    $loc->localize( "lexicon_key", { name => "John" } );

=head1 METHODS

=head2 format

=cut
