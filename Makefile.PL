use strict;
use inc::Module::Install;

name('Data-Localize');
all_from('lib/Data/Localize.pm');

requires 'Any::Moose';
requires 'Module::Pluggable::Object';
requires 'I18N::LangTags';
requires_any_moose 'mouse' => '0.19';

recommends 'BerkeleyDB';

test_requires 'Test::More' => 0.94;
test_requires 'Test::Requires';

author_tests 'xt';
auto_set_repository;
auto_include_deps;
no_index directory => 'tools';

WriteAll;
