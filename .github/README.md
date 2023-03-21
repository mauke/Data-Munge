[![Coverage Status](https://coveralls.io/repos/github/mauke/Data-Munge/badge.svg?branch=main)](https://coveralls.io/github/mauke/Data-Munge?branch=main)

# NAME

Data::Munge - various utility functions

# SYNOPSIS

```perl
use Data::Munge;

my $re = list2re qw/f ba foo bar baz/;
# $re = qr/bar|baz|foo|ba|f/;

print byval { s/foo/bar/ } $text;
# print do { my $tmp = $text; $tmp =~ s/foo/bar/; $tmp };

foo(mapval { chomp } @lines);
# foo(map { my $tmp = $_; chomp $tmp; $tmp } @lines);

print replace('Apples are round, and apples are juicy.', qr/apples/i, 'oranges', 'g');
# "oranges are round, and oranges are juicy."
print replace('John Smith', qr/(\w+)\s+(\w+)/, '$2, $1');
# "Smith, John"

my $trimmed = trim "  a b c ";
# "a b c"

my $x = 'bar';
if (elem $x, [qw(foo bar baz)]) { ... }
# executes: $x is an element of the arrayref

my $contents = slurp $fh;  # or: slurp *STDIN
# reads all data from a filehandle into a scalar

eval_string('print "hello world\\n"');  # says hello
eval_string('die');  # dies
eval_string('{');    # throws a syntax error

my $fac = rec {
  my ($rec, $n) = @_;
  $n < 2 ? 1 : $n * $rec->($n - 1)
};
print $fac->(5);  # 120

if ("hello, world!" =~ /(\w+), (\w+)/) {
  my @captured = submatches;
  # @captured = ("hello", "world")
}
```

# DESCRIPTION

This module defines a few generally useful utility functions. I got tired of
redefining or working around them, so I wrote this module.

## Functions

- list2re LIST

    Converts a list of strings to a regex that matches any of the strings.
    Especially useful in combination with `keys`. Example:

    ```perl
    my $re = list2re keys %hash;
    $str =~ s/($re)/$hash{$1}/g;
    ```

    This function takes special care to get several edge cases right:

    - Empty list: An empty argument list results in a regex that doesn't match
    anything.
    - Empty string: An argument list consisting of a single empty string results in a
    regex that matches the empty string (and nothing else).
    - Prefixes: The input strings are sorted by descending length to ensure longer
    matches are tried before shorter matches. Otherwise `list2re('ab', 'abcd')`
    would generate `qr/ab|abcd/`, which (on its own) can never match `abcd`
    (because `ab` is tried first, and it always succeeds where `abcd` could).

- byval BLOCK SCALAR

    Takes a code block and a value, runs the block with `$_` set to that value,
    and returns the final value of `$_`. The global value of `$_` is not
    affected. `$_` isn't aliased to the input value either, so modifying `$_`
    in the block will not affect the passed in value. Example:

    ```perl
    foo(byval { s/!/?/g } $str);
    # Calls foo() with the value of $str, but all '!' have been replaced by '?'.
    # $str itself is not modified.
    ```

    Since perl 5.14 you can also use the `/r` flag:

    ```perl
    foo($str =~ s/!/?/gr);
    ```

    But `byval` works on all versions of perl and is not limited to `s///`.

- mapval BLOCK LIST

    Works like a combination of `map` and `byval`; i.e. it behaves like
    `map`, but `$_` is a copy, not aliased to the current element, and the return
    value is taken from `$_` again (it ignores the value returned by the
    block). Example:

    ```perl
    my @foo = mapval { chomp } @bar;
    # @foo contains a copy of @bar where all elements have been chomp'd.
    # This could also be written as chomp(my @foo = @bar); but that's not
    # always possible.
    ```

- submatches

    Returns a list of the strings captured by the last successful pattern match.
    Normally you don't need this function because this is exactly what `m//`
    returns in list context. However, `submatches` also works in other contexts
    such as the RHS of `s//.../e`.

- replace STRING, REGEX, REPLACEMENT, FLAG
- replace STRING, REGEX, REPLACEMENT

    A clone of javascript's `String.prototype.replace`. It works almost the same
    as `byval { s/REGEX/REPLACEMENT/FLAG } STRING`, but with a few important
    differences. REGEX can be a string or a compiled `qr//` object. REPLACEMENT
    can be a string or a subroutine reference. If it's a string, it can contain the
    following replacement patterns:

    - $$

        Inserts a '$'.

    - $&

        Inserts the matched substring.

    - $\`

        Inserts the substring preceding the match.

    - $'

        Inserts the substring following the match.

    - $N  (where N is a digit)

        Inserts the substring matched by the Nth capturing group.

    - ${N}  (where N is one or more digits)

        Inserts the substring matched by the Nth capturing group.

    Note that these aren't variables; they're character sequences interpreted by
    `replace`.

    If REPLACEMENT is a subroutine reference, it's called with the following
    arguments: First the matched substring (like `$&` above), then the contents of
    the capture buffers (as returned by `submatches`), then the offset where the
    pattern matched (like `$-[0]`, see ["@-" in perlvar](https://metacpan.org/pod/perlvar#pod)), then the STRING. The return
    value will be inserted in place of the matched substring.

    Normally only the first occurrence of REGEX is replaced. If FLAG is present, it
    must be `'g'` and causes all occurrences to be replaced.

- trim STRING

    Returns _STRING_ with all leading and trailing whitespace removed. Like
    [`length`](https://metacpan.org/pod/perlfunc#length-EXPR) it returns `undef` if the input is `undef`.

- elem SCALAR, ARRAYREF

    Returns a boolean value telling you whether _SCALAR_ is an element of
    _ARRAYREF_ or not. Two scalars are considered equal if they're both `undef`,
    if they're both references to the same thing, or if they're both not references
    and `eq` to each other.

    This is implemented as a linear search through _ARRAYREF_ that terminates
    early if a match is found (i.e. `elem 'A', ['A', 1 .. 9999]` won't even look
    at elements `1 .. 9999`).

- eval\_string STRING

    Evals _STRING_ just like `eval` but doesn't catch exceptions. Caveat: Unlike
    with `eval` the code runs in an empty lexical scope:

    ```perl
    my $foo = "Hello, world!\n";
    eval_string 'print $foo';
    # Dies: Global symbol "$foo" requires explicit package name
    ```

    That is, the eval'd code can't see variables from the scope of the
    `eval_string` call.

- slurp FILEHANDLE

    Reads and returns all remaining data from _FILEHANDLE_ as a string, or
    `undef` if it hits end-of-file. (Interaction with non-blocking filehandles is
    currently not well defined.)

    `slurp $handle` is equivalent to `do { local $/; scalar readline $handle }`.

- rec BLOCK

    Creates an anonymous sub as `sub BLOCK` would, but supplies the called sub
    with an extra argument that can be used to recurse:

    ```perl
    my $code = rec {
      my ($rec, $n) = @_;
      $rec->($n - 1) if $n > 0;
      print $n, "\n";
    };
    $code->(4);
    ```

    That is, when the sub is called, an implicit first argument is passed in
    `$_[0]` (all normal arguments are moved one up). This first argument is a
    reference to the sub itself. This reference could be used to recurse directly
    or to register the sub as a handler in an event system, for example.

    A note on defining recursive anonymous functions: Doing this right is more
    complicated than it may at first appear. The most straightforward solution
    using a lexical variable and a closure leaks memory because it creates a
    reference cycle. Starting with perl 5.16 there is a `__SUB__` constant that is
    equivalent to `$rec` above, and this is indeed what this module uses (if
    available).

    However, this module works even on older perls by falling back to either weak
    references (if available) or a "fake recursion" scheme that dynamically
    instantiates a new sub for each call instead of creating a cycle. This last
    resort is slower than weak references but works everywhere.

# AUTHOR

Lukas Mai, `<l.mai at web.de>`

# COPYRIGHT & LICENSE

Copyright 2009-2011, 2013-2015, 2023 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/) for more information.
