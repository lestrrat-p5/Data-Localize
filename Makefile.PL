use strict;
use inc::Module::Install;

name('Data-Localize');
all_from('lib/Data/Localize.pm');

requires 'Any::Moose';
requires 'Module::Pluggable::Object';
requires 'I18N::LangTags';
requires_any_moose 'mouse' => '0.19';
requires_any_moose 'X::AttributeHelpers' => (
    prefer => 'Mouse',
    moose  => '0.13',
    mouse  => '0.01',
);
recommends 'BerkeleyDB';

test_requires 'Test::Requires';

no_index directory => 't/lib';

auto_include_deps;
no_index directory => 'tools';

WriteAll;
