use inc::Module::Install;

name     'POE-Declarative';
all_from 'lib/POE/Declarative.pm';

requires 'POE';

auto_install;
WriteMakefile;
