use strict;
use inc::Module::Install;

name('Data-Localize');
all_from('lib/Data/Localize.pm');

requires 'Moo' => '1.000008';
requires 'MooX::Types::MooseLike::Base';
requires 'Encode';
requires 'I18N::LangTags';
requires 'I18N::LangTags::Detect';
requires 'Log::Minimal' => '0.14';
requires 'Module::Load';
requires 'Module::Pluggable::Object';

recommends 'BerkeleyDB';
recommends 'Config::Any';

test_requires 'Test::More' => 0.94;
test_requires 'Test::Requires';

no_index directory => 'tools';

author_tests 'xt';
auto_set_repository;

WriteAll;
