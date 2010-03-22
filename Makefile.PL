use strict;
use inc::Module::Install;

name('Data-Localize');
all_from('lib/Data/Localize.pm');

requires 'Any::Moose';
requires 'Encode';
requires 'I18N::LangTags';
requires 'I18N::LangTags::Detect';
requires 'Module::Pluggable::Object';

requires_any_moose 'mouse' => '0.19';

recommends 'BerkeleyDB';

test_requires 'Test::More' => 0.94;
test_requires 'Test::Requires';

no_index directory => 'tools';

author_tests 'xt';
auto_set_repository;
auto_include_deps;

WriteAll;
