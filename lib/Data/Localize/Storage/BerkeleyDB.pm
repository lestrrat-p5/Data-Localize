package Data::Localize::Storage::BerkeleyDB;
use Any::Moose;
use BerkeleyDB;

with 'Data::Localize::Storage';

has 'db' => (
    is => 'rw',
    isa => ' BerkeleyDB::Hash | BerkeleyDB::Btree | BerkeleyDB::Recno | BerkeleyDB::Queue '
);

sub BUILD {
    my ($self, $args) = @_;
    if (! $self->db) {
        my $class = $args->{bdb_class} || 'Hash';
        if ($class !~ s/^\+//) {
            $class = "BerkeleyDB::$class";
        }
        Any::Moose::load_class($class);
        $self->db( $class->new( $args->{bdb_args} || {} ) ||
            confess "Failed to create $class: $BerkeleyDB::Error"
        );
    }
    $self;
}

sub get {
    my ($self, $key, $flags) = @_;
    my $value;
    my $rc = $self->db->db_get($key, $value, $flags || 0);
    if ($rc == 0) {
        # BerkeleyDB gives us values with the flags off, so put them back on
        Encode::_utf8_on($value);
        return $value;
    }
    return ();
}

sub set {
    my ($self, $key, $value, $flags) = @_;
    my $rc = $self->db->db_put($key, $value, $flags || 0);
    if ($rc != 0) {
        confess "Failed to set value $key";
    }
}

__PACKAGE__->meta->make_immutable();

no Any::Moose;

1;

__END__

=head1 NAME

Data::Localize::Storage::BerkeleyDB - BerkeleyDB Backend

=head1 SYNOPSIS

    use Data::Localize::Storage::BerkeleyDB;

    Data::Localize::Storage::BerkeleDB->new(
        bdb_class => 'Hash', # default
        bdb_args  => {
            -Filename => ....
            -Flags    => BerkeleyDB::DB_CREATE
        }
    );

=head1 METHODS

=head2 get

=head2 set

=cut