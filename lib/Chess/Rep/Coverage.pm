package Chess::Rep::Coverage;
our $VERSION = '0.05_01';
use strict;
use warnings;
use base 'Chess::Rep';

my $piece_to_id = Chess::Rep::PIECE_TO_ID;
$piece_to_id = { reverse %$piece_to_id };

sub covers {
    my $self = shift;
    my %args = (
        -as_field   => 0,
        -protection => 0,
        @_
    );

    my $cover = {};
    my $action = $args{-protection} ? 'protects' : 'attacks';

    for my $piece (@{$self->status->{pieces}}) {

        my $from = $args{-as_field}
            ? Chess::Rep::get_field_id($piece->{from})
            : $piece->{from};

        for my $t (@{$piece->{to}}) {
#            $cover->{$from}{controls} = $args{-as_field}
#                ? [map { Chess::Rep::get_field_id($_) } @{$piece->{to}}]
#                : $piece->{to};

            my @at = $self->get_piece_at($t);
            push @{$cover->{$from}{$action}}, ($args{-as_field}
                ? Chess::Rep::get_field_id($at[1])
                : $at[1]) if $at[0];
        }

        if (!$args{-protection}) {
            my $p = $self->_protects(-as_field => $args{-as_field}, -piece => $piece);
            push @{$cover->{$from}{protects}}, @$p if defined $p;
        }
    }

    return $cover; 
}

sub _protects { # Flip enemies and compute protection.
    my $self = shift;
    my %args = (
        -as_field => 0,
        @_
    );
    my $piece = $args{-piece} || return undef;

    my $cover = {};

    my $f = $self->get_fen;
    my @f = split / /, $f, 2;
    my $n = '';
    for (split //, $f[0]) {
        if (/[pnkbrq]/) {
            $n .= uc $_
        }
        elsif (/[PNKBRQ]/) {
            $n .= lc $_
        }
        else {
            $n .= $_
        }
    }
    $f = $n . ' ' . $f[1];

    my $from = $args{-as_field}
        ? Chess::Rep::get_field_id($piece->{from})
        : $piece->{from};

    my $p = Chess::Rep::Coverage->new($f);
    $p->set_piece_at($piece->{from}, $piece->{piece});
    $p->compute_valid_moves;
    $cover = $p->covers(-as_field => $args{-as_field}, -protection => 1);

    return $cover->{$from}{protects};
}

sub _dump_coverage {
    my $self = shift;
    warn"- Under construction - Until then, here's what we have:\n";
    print $self->dump_pos, "\n";
}

1;

__END__

=head1 NAME

Chess::Rep::Coverage - Expose chess ply potential energy

=head1 SYNOPSIS

  use Chess::Rep::Coverage;
  $g = Chess::Rep::Coverage->new;
  $c = $g->covers;
  # ...

=head1 DESCRTIPTION

This module exposes the "potential energy" of a chess ply by returning
a hash reference of the board positions and their "attack status",
based on the occupying piece.

=head1 METHODS

=head2 new()

Subclass L<Chess::Rep>.

=head2 covers()

Return a data structure, keyed on board index or position (a "field"),
with:

  protects => [squares occupied by protected allies]
  attacks  => [squares occupied by attacted opponents]

=head1 TO DO

Make additional methods to produce coverage images and animations.

=head1 SEE ALSO

L<Chess::Rep>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007-2010, Gene Boggs

This code is licensed under the same terms as Perl itself.

=cut
