
package Data::Localize::Namespace;
use Any::Moose;
use Module::Pluggable::Object;
use Encode ();
use Data::Localize::Util qw(_alias_and_deprecate);

extends 'Data::Localize::Localizer';

has _namespaces => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    init_arg => 'namespaces',
);

has _loaded_classes => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has _failed_classes => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

override register => sub {
    my ($self, $loc) = @_;
    super();

    my $finder = Module::Pluggable::Object->new(
        'require' => 1,
        search_path => [ $self->namespaces ]
    );

    # find the languages that we currently support
    my $re = join('|', $self->namespaces);
    foreach my $plugin ($finder->plugins) {
        $plugin =~ s/^(?:$re):://;
        $plugin =~ s/::/_/g;
        $loc->add_localizer_map($plugin, $self);
    }   
    $loc->add_localizer_map('*', $self);
};

_alias_and_deprecate lexicon_get => 'get_lexicon';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub add_namespaces {
    my $self = shift;
    unshift @{ $self->_namespaces }, @_;
}

sub namespaces {
    my $self = shift;
    return @{ $self->_namespaces };
}

sub get_lexicon {
    my ($self, $lang, $id) = @_;

    $lang =~ s/-/_/g;

    my $LOADED = $self->_loaded_classes;
    my $FAILED = $self->_failed_classes;
    foreach my $namespace ($self->namespaces) {
        my $klass = "$namespace\::$lang";

        if ($FAILED->{ $klass }++) {
            if (Data::Localize::DEBUG()) {
                print STDERR "[Data::Localize::Namespace]: get_lexicon - Already attempted loading $klass and failed. Skipping...\n";
            }
            next;
        }

        if (Data::Localize::DEBUG()) {
            print STDERR "[Data::Localize::Namespace]: get_lexicon - Trying $klass\n";
        }

        # Catch the very weird case where is_class_loaded() returns true
        # but the class really hasn't been loaded yet.
        no strict 'refs';
        my $first_load = 0;
        if (! $LOADED->{$klass}) {
            if (%{"$klass\::Lexicon"} && %{"$klass\::"}) {
                if (Data::Localize::DEBUG()) {
                    print STDERR "[Data::Localize::Namespace]: get_lexicon - class already loaded\n";
                }
            } else {
                if (Data::Localize::DEBUG()) {
                    print STDERR "[Data::Localize::Namespace]: get_lexicon - loading $klass\n";
                }

                my $code = 
                    "\n" .
                    "#line " . __LINE__ . ' "' . __FILE__ . '"' . "\n" .
                    "require $klass;"
                ;
                eval($code);
                if ($@) {
                    if (Data::Localize::DEBUG()) {
                        print STDERR "[Data::Localize::Namespace]: get_lexicon - Failed to load $klass: $@\n";
                        $FAILED->{$klass}++;
                    }
                    next;
                }
            }
            if (Data::Localize::DEBUG()) {
                print STDERR "[Data::Localize::Namespace]: get_lexicon - setting $klass to already loaded\n";
            }
            $LOADED->{$klass}++;
            $first_load = 1;
        }

        if (Data::Localize::DEBUG()) {
            print STDERR "[Data::Localize::Namespace]: returning lexicon from $klass (", scalar keys %{"$klass\::Lexicon"}, " lexicons)\n";
        }
        my $h = \%{ "$klass\::Lexicon" };
        if ($first_load) {
            my %t;
            while (my($k, $v) = each %$h) {
                if ( ! Encode::is_utf8($k) ) {
                    $k = Encode::decode_utf8($k);
                }
                if ( ! Encode::is_utf8($v) ) {
                    $v = Encode::decode_utf8($v);
                }
                $t{$k} = $v;
            }
            %$h = ();
            %$h = %t;
        }
        return $h->{$id};
        
    }
    return ();
}

1;

__END__

=head1 NAME

Data::Localize::Namespace - Acquire Lexicons From Module %Lexicon Hash

=head1 SYNOPSIS

   package MyApp::I18N::ja;
   use strict;
   our %Lexicon = (
      "Greeting" => "[_1]さん、こんにちは!"
   );

   1;

   use Data::Localize;

   my $loc = Data::Localize::Namespace->new(
      namespace => "MyApp::I18N",
   );
   my $out = $loc->localize_for(
      lang => 'ja',
      id   => 'Greeting',
      args => [ 'John Doe' ]
   );

=head1 METHODS

=head2 add_namespaces

Add a new namespace to the END of the namespace list

=head2 get_lexicon 

Looks up lexicon data from given namespaces. Packages must be discoverable
via Module::Pluggable::Object, with a package name like YourNamespace::lang

=head2 namespaces

Get all the namespaces that this localizer will look up, in the order that
they will be looked up.

=head2 register

Registers this localizer to the Data::Localize object

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT

=over 4

=item The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=back

=cut
