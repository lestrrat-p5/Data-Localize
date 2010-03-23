package Data::Localize::Format;
use Any::Moose;
no Any::Moose;

sub format { Carp::confess("format() must be overridden") }

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Data::Localize::Format - Base Format Class

=head1 METHODS

=head2 format

Must be overridden in subclasses

=cut
