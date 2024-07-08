use strict;
use warnings;

use Pod::Markdown::Githubert ();

binmode $_ for \*STDIN, \*STDOUT;

my $parser = Pod::Markdown::Githubert->new(
    output_encoding => 'UTF-8',
);
$parser->output_fh(\*STDOUT);
$parser->parse_file(\*STDIN);
