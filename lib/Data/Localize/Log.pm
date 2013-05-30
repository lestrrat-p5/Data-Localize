package Data::Localize::Log;
use strict;
use base qw(Exporter);
use Log::Minimal ();
our @EXPORT;
our $PRINT;
BEGIN {
    @EXPORT = @Log::Minimal::EXPORT;
    $PRINT = sub {
        printf STDERR "%5s [%s] %s\n",
            $$,
            $_[1],
            $_[2],
    };
    $Log::Minimal::ENV_DEBUG = 'DATA_LOCALIZE_DEBUG';
    foreach my $sub (@EXPORT) {
        no strict 'refs';
        *{$sub} = sub {
            local $Log::Minimal::PRINT = $PRINT;
            (\&{"Log::Minimal::$sub"})->(@_);
        }
    }
}

1;
