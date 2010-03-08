#!perl

use Test::More tests => 6;

use warnings;
use strict;
use Data::Munge;

{
	my $str = "abc|bar|baz|foo|\\*\\*|ab|\\!|\\*|a";
	is list2re(qw[! a abc ab foo bar baz ** *]), qr/$str/, 'list2re';
}

is +(byval { s/foo/bar/ } 'foo-foo'), 'bar-foo', 'byval';
is_deeply [mapval { tr[a-d][1-4] } qw[foo bar baz]], [qw[foo 21r 21z]], 'mapval';
is replace('Apples are round, and apples are juicy.', qr/apples/i, 'oranges', 'g'), 'oranges are round, and oranges are juicy.', 'replace g';
is replace('John Smith', qr/(\w+)\s+(\w+)/, '$2, $1'), 'Smith, John', 'replace';
is replace('97653 foo bar 42', qr/(\d)(\d)/, sub { $_[1] + $_[2] }, 'g'), '16113 foo bar 6', 'replace fun g';
