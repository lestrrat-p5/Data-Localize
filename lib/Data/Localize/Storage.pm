package Data::Localize::Storage;
use Any::Moose '::Role';

has 'lang' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

requires qw(get set);

no Any::Moose '::Role';

1;

__END__

=head1 NAME

Data::Localize::Storage - Base Role For Storage Objects

=head1 SYNOPSIS

    package MyStorage;
    use Any::Moose;

    with 'Data::Localize::Storage';

    sub get { ... }
    sub set { ... }

=cut
