use strict;
use warnings;

sub MY::postamble {
    my ($self, %args) = @_;
    $args{text} || ''
}

sub {
    my ($opt) = @_;
    $opt->{postamble}{text} .= <<"EOT";
export RELEASE_TESTING=1
export HARNESS_OPTIONS=c
EOT
}
