# $Id: Namespace.pm 32372 2009-04-14 06:21:48Z daisuke $

package Data::Localize::Namespace;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use Module::Pluggable::Object;
use Encode ();

with 'Data::Localize::Localizer';

has 'namespaces' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    provides => {
        unshift => 'add_namespaces'
    }
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub register {
    my ($self, $loc) = @_;
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
}

our %LOADED;
our %ATTEMPTED;
sub lexicon_get {
    my ($self, $lang, $id) = @_;

    $lang =~ s/-/_/g;

    foreach my $namespace ($self->namespaces) {
        my $klass = "$namespace\::$lang";

        if ($ATTEMPTED{ $klass }++) {
            if (Data::Localize::DEBUG()) {
                print STDERR "[Data::Localize::Namespace]: lexicon_get - Already attempted loading $klass and failed. Skipping...\n";
            }
            next;
        }

        if (Data::Localize::DEBUG()) {
            print STDERR "[Data::Localize::Namespace]: lexicon_get - Trying $klass\n";
        }

        # Catch the very weird case where is_class_loaded() returns true
        # but the class really hasn't been loaded yet.
        no strict 'refs';
        my $first_load = 0;
        if (! $LOADED{$klass}) {
            if (defined %{"$klass\::Lexicon"} && defined %{"$klass\::"}) {
                if (Data::Localize::DEBUG()) {
                    print STDERR "[Data::Localize::Namespace]: lexicon_get - class already loaded\n";
                }
            } else {
                if (Data::Localize::DEBUG()) {
                    print STDERR "[Data::Localize::Namespace]: lexicon_get - loading $klass\n";
                }

                my $code = 
                    "\n" .
                    "#line " . __LINE__ . ' "' . __FILE__ . '"' . "\n" .
                    "require $klass;"
                ;
                eval($code);
                if ($@) {
                    if (Data::Localize::DEBUG()) {
                        print STDERR "[Data::Localize::Namespace]: lexicon_get - Failed to load $klass: $@\n";
                    }
                    next;
                }
            }
            if (Data::Localize::DEBUG()) {
                print STDERR "[Data::Localize::Namespace]: lexicon_get - setting $klass to already loaded\n";
            }
            $LOADED{$klass}++;
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
      "Hello, %1!" => "%1さん、こんにちは!"
   );

   1;

   use Data::Localize;

   my $loc = Data::Localize::Namespace->new(
      style => "gettext",
      namespace => "MyApp::I18N",
   );
   my $out = $loc->localize_for(
      lang => 'ja',
      id   => 'Hello, %1!',
      args => [ 'John Doe' ]
   );

=head1 METHODS

=head2 register

Registeres this localizer to the Data::Localize object

=head2 lexicon_get 

Looks up lexicon data from given namespaces. Packages must be discoverable
via Module::Pluggable::Object, with a package name like YourNamespace::lang

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