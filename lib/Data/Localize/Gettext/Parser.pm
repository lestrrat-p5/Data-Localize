package Data::Localize::Gettext::Parser;
use Any::Moose;
use namespace::autoclean;

has 'encoding' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'use_fuzzy' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has 'keep_empty' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has '_lexicon' => (
    is => 'rw',
    isa => 'HashRef',
);

has '_msgids' => (
    is => 'rw',
    isa => 'HashRef',
);

sub parse_file {
    my ($self, $file) = @_;

    my $enc = ':encoding(' . $self->encoding . ')';
    open(my $fh, "<$enc", $file) or die "Could not open $file: $!";

    $self->_lexicon( {} );

    my @block = ();

    while ( defined( my $line = <$fh> ) ) {
        $line =~ s/[\015\012]*\z//;                  # fix CRLF issues

        if ( $line =~ /^\s*$/ ) {
            $self->_process_block(\@block) if @block;
            @block = ();
            next;
        }

        push @block, $line;
    }

    $self->_process_block(\@block) if @block;

    return $self->_lexicon();
}

sub _process_block {
    my ($self, $block) = @_;

    my $msgid = q{};
    my $msgstr = q{};
    my $value;
    my $is_fuzzy = 0;

    # Note that we are ignoring the various types of comments allowed in a .po
    # file - see
    # http://www.gnu.org/software/gettext/manual/gettext.html#PO-Files for
    # more details.
    #
    # We do not handle the msgstr[0]/msgstr[1] type of string.
    #
    # Finally, we don't handle msgctxt at all.
    for my $line (@{$block} ) {
        if ( $line =~ /^msgid\s+"(.*)"\s*$/ ) {
            $value = \$msgid;

            ${$value} .= $1;
        }
        elsif ( $line =~ /^msgstr\s+"(.*)"\s*$/ ) {
            $value = \$msgstr;

            ${$value} .= $1;
        }
        elsif ( $line =~ /^"(.*)"\s*$/ ) {
            ${$value} .= $1;
        }
        elsif ( $line =~ /#,\s+.*fuzzy.*$/ ) {
            $is_fuzzy = 1;
        }
    }

    return unless length $msgstr || $self->keep_empty();

    return if $is_fuzzy && ! $self->use_fuzzy();

    s/\\(n|\\)/$1 eq 'n' ? "\n" : "\\" /ge for $msgid, $msgstr;

    $self->_lexicon()->{$msgid} = $msgstr;

    return;
}

1;
