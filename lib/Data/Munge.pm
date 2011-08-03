package Data::Munge;

use warnings;
use strict;
use Exporter qw[import];

our $VERSION = '0.04';
our @EXPORT = our @EXPORT_OK = qw[list2re byval mapval submatches replace];

sub list2re {
	@_ or return qr/(?!)/;
	my $re = join '|', map quotemeta, sort {length $b <=> length $a || $a cmp $b } @_;
	$re eq '' and $re = '(?#)';
	qr/$re/
}

sub byval (&$) {
	my ($f, $x) = @_;
	local *_ = \$x;
	$f->($_);
	$x
}

sub mapval (&@) {
	my $f = shift;
	my @xs = @_;
	map { $f->($_); $_ } @xs
}

sub submatches {
	no strict 'refs';
	map $$_, 1 .. $#+
}

sub replace {
	my ($str, $re, $x, $g) = @_;
	my $f = ref $x ? $x : sub {
		my $r = $x;
		$r =~ s{\$([\$&`'0-9]|\{([0-9]+)\})}{
			$+ eq '$' ? '$' :
			$+ eq '&' ? $_[0] :
			$+ eq '`' ? substr($_[-1], 0, $_[-2]) :
			$+ eq "'" ? substr($_[-1], $_[-2] + length $_[0]) :
			$_[$+]
		}eg;
		$r
	};
	if ($g) {
		$str =~ s{$re}{ $f->(substr($str, $-[0], $+[0] - $-[0]), submatches, $-[0], $str) }eg;
	} else {
		$str =~ s{$re}{ $f->(substr($str, $-[0], $+[0] - $-[0]), submatches, $-[0], $str) }e;
	}
	$str
}

1

__END__

=head1 NAME

Data::Munge - various utility functions

=head1 SYNOPSIS

 use Data::Munge;
 
 my $re = list2re qw/foo bar baz/;
 print byval { s/foo/bar/ } $text;
 foo(mapval { chomp } @lines);
 print replace('Apples are round, and apples are juicy.', qr/apples/i, 'oranges', 'g');
 print replace('John Smith', qr/(\w+)\s+(\w+)/, '$2, $1');

=head1 DESCRIPTION

This module defines a few generally useful utility functions. I got tired of
redefining or working around them, so I wrote this module.

=head2 Functions

=over 4

=item list2re LIST

Converts a list of strings to a regex that matches any of the strings.
Especially useful in combination with C<keys>. Example:

 my $re = list2re keys %hash;
 $str =~ s/($re)/$hash{$1}/g;

=item byval BLOCK SCALAR

Takes a code block and a value, runs the block with C<$_> set to that value,
and returns the final value of C<$_>. The global value of C<$_> is not
affected. C<$_> isn't aliased to the input value either, so modifying C<$_>
in the block will not affect the passed in value. Example:

 foo(byval { s/!/?/g } $str);
 # Calls foo() with the value of $str, but all '!' have been replaced by '?'.
 # $str itself is not modified.

=item mapval BLOCK LIST

Works like a combination of C<map> and C<byval>; i.e. it behaves like
C<map>, but C<$_> is a copy, not aliased to the current element, and the return
value is taken from C<$_> again (it ignores the value returned by the
block). Example:

 my @foo = mapval { chomp } @bar;
 # @foo contains a copy of @bar where all elements have been chomp'd.
 # This could also be written as chomp(my @foo = @bar); but that's not
 # always possible.

=item submatches

Returns a list of the strings captured by the last successful pattern match.
Normally you don't need this function because this is exactly what C<m//>
returns in list context. However, C<submatches> also works in other contexts
such as the RHS of C<s//.../e>.

=item replace STRING, REGEX, REPLACEMENT, FLAG

=item replace STRING, REGEX, REPLACEMENT

A clone of javascript's C<String.prototype.replace>. It works almost the same
as C<byval { s/REGEX/REPLACEMENT/FLAG } STRING>, but with a few important
differences. REGEX can be a string or a compiled C<qr//> object. REPLACEMENT
can be a string or a subroutine reference. If it's a string, it can contain the
following replacement patterns:

=over

=item $$

Inserts a '$'.

=item $&

Inserts the matched substring.

=item $`

Inserts the substring preceding the match.

=item $'

Inserts the substring following the match.

=item $N  (where N is a digit)

Inserts the substring matched by the Nth capturing group.

=item ${N}  (where N is one or more digits)

Inserts the substring matched by the Nth capturing group.

=back

Note that these aren't variables; they're character sequences interpreted by C<replace>.

If REPLACEMENT is a subroutine reference, it's called with the following
arguments: First the matched substring (like C<$&> above), then the contents of
the capture buffers (as returned by C<submatches>), then the offset where the
pattern matched (like C<$-[0]>, see L<perlvar/@->), then the STRING. The return
value will be inserted in place of the matched substring.

Normally only the first occurrence of REGEX is replaced. If FLAG is present, it
must be C<'g'> and causes all occurrences to be replaced.

=back

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
