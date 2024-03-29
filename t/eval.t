use Test2::V0;
use Data::Munge qw(eval_string);

{
    $@ = 'xyzzy 1';
    eval_string '$main::E = $@';
    is $@, 'xyzzy 1';
    is $main::E, 'xyzzy 1';
}

{
    eval {
        $@ = 'xyzzy 2';
        eval_string '$main::E = $@; die "fiddlesticks\\n"';
        fail 'wtf';
    };
    is $@, "fiddlesticks\n";
    is $main::E, 'xyzzy 2';
}

done_testing;
