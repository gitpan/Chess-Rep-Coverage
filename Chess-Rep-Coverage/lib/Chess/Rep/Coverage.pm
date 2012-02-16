package Chess::Rep::Coverage;
# ABSTRACT: Expose chess ply potential energy

=head1 NAME

Chess::Rep::Coverage - Expose chess ply potential energy

=cut

use strict;
use warnings;

use base 'Chess::Rep';

our $VERSION = '0.05';

=head1 SYNOPSIS

  use Chess::Rep::Coverage;
  $g = Chess::Rep::Coverage->new();
  $c = $g->coverage();

=head1 DESCRIPTION

This module exposes the "potential energy" of a chess ply by returning
a hash reference of the board positions, pieces and their "attack or
protection status."

=head1 METHODS

=head2 new()

Return a new C<Chess::Coverage> object.

=head2 coverage()

  $x = Chess::Rep::Coverage::coverage();

Return a data structure, keyed on board position, showing

  occupant   => Human readable string of the piece name
  color      => Color name of the occupant
  index      => The C<Chess::Rep/Position> board position index
  move       => List of positions that are legal moves by the occupying piece
  protected  => True (1) if the occupying piece is protected by its own color
  threatened => True (1) if the occupying piece is threatened by the opponent

=cut

sub coverage {
    my $self = shift;

    my $fen = $self->get_fen();
#warn"Original FEN: $fen\n";

    my $cover = {};

    my %pieces;
    @pieces{values %{+Chess::Rep::PIECE_TO_ID()}} = keys %{+Chess::Rep::PIECE_TO_ID()};

    for my $row (0 .. 7) {
        for my $col (0 .. 7) {
            my $p = $self->get_piece_at($row, $col) || ''; # decimal of index
            if ($p) {
                my $c = Chess::Rep::piece_color($p); # 0=black, 0x80=white
                my $i = Chess::Rep::get_index($row, $col); # $row << 4 | $col
                my $f = Chess::Rep::get_field_id($i); # A-H, 1-8
#warn"Piece: $p I: $i, F: $f, C: $c\n";

                $cover->{$f}{occupant} = $pieces{$p};
                $cover->{$f}{piece} = $p;
                $cover->{$f}{color} = $c;
                $cover->{$f}{index} = $i;

                # Swap the "next to move" color to the piece
                $self->to_move($c);
#warn"$cover->{$f}{occupant} ($c) to move: ",$self->to_move,"\n";

                # Invert the FEN to compute all possible moves, threasts and protections.
#                my $inverted_fen = _invert_fen($fen, $row, $col, $c);
#                $self->set_from_fen($inverted_fen);
#warn"New: $new_fen\n";

                # Recompute the move status.
                $self->compute_valid_moves;
                # Collect the moves of the piece.
                my $moves = [ map { $_->{to} } grep { $_->{from} == $i } @{ $self->status->{moves} } ];

                # Reset original game FEN.
#                $self->set_from_fen($fen);

                # Find the threats and protections.
                if (@$moves) {
                    $cover->{$f}{move} = $moves;
                    for my $m (@$moves) {
                        my $x = $self->get_piece_at($m) || '';
                        next unless $x;
                        if (Chess::Rep::piece_color($x) == $c) {
                            push @{$cover->{$f}{protects}}, $m;
                        }
                        else {
                            push @{$cover->{$f}{threatens}}, $m;
                        }
                    }
                }
            }
        }
    }

    return $cover;
}

sub _invert_fen {
    my ($fen, $row, $col, $color) = @_;

    # Grab the board positions only.
    $fen =~ s/^(.+?)\s.*$/$1/;
#warn"[$color, $row, $col] FEN: '$fen'\n";
    # Convert pieces to all black or all white, given the piece color.
    $fen = $color ? lc $fen : uc $fen;
    # Split the FEN into rows.
    my @fen = split /\//, $fen; # rows: 7..0, cols: 0..7
    # The FEN sections are the rows reversed.
    $row = 7 - $row;
#warn"$fen[$row]\n";

    # Find the position of the piece to invert.
    my $n = 0;
    my $p = 0;
    for my $i (split //, $fen[$row]) {
#warn"1 n: $n, p: $p\n";
        if ($i =~ /^\d$/) {
            $n += $i;
        }
        else {
            if ($n == $row) {
#warn"P($n): $i\n";
                substr($fen[$row], $p, 1) = $i ^ "\x20";
                last;
            }
            else {
                $n++;
            }
        }

        $p++;
#warn"2 n: $n, p: $p\n";
    }

    return join '/', @fen;
}

1;
__END__

=head1 TO DO

Get C<Chess::Rep> to return the indices of the protectors.

Make additional methods (or plugins) produce images and animations of
the coverage.

=head1 SEE ALSO

* The code in the C<eg/> and C<t/> directories.

* L<Chess::Rep>

=cut
