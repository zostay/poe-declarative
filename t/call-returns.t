use strict;
use warnings;

use Test::More tests => 20;

use POE;
use POE::Declarative;

on _start => run {
    my $session = get SESSION;
    for ( 1 .. 10 ) {
        my $result = call $session => 'return_a_value';
        is($result, $_);

        my @result = call $session => 'return_some_values';
        is(scalar(@result), $_);
    }
};

my $val = 0;
on return_a_value => run {
    return ++$val;
};

my $num = 0;
on return_some_values => run {
    return ('X') x ++$num;
};

POE::Declarative->setup;
POE::Kernel->run;
