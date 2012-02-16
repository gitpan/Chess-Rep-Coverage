package Chess::Rep::Coverage;
# ABSTRACT: Expose chess ply potential energy

=head1 NAME

Chess::Rep::Coverage - Expose chess ply potential energy

=cut

use strict;
use warnings;

use base 'Chess::Rep';

our $VERSION = '0.0601';

=head1 SYNOPSIS

  use Chess::Rep::Coverage;
  $g = Chess::Rep::Coverage->new();
  $c = $g->coverage();
  warn Data::Dumper->new([$c])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;

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

  occupant  => Human readable string of the piece name
  color     => Color name of the occupant
  index     => The C<Chess::Rep/Position> board position index
  move      => List of positions that are legal moves by the occupying piece
  protects  => True (1) if the occupying piece is protected by its own color
  threatens => True (1) if the occupying piece is threatened by the opponent

=cut

sub coverage {
    my $self = shift;

    # What is the state of our board?
    my $fen = $self->get_fen();

    # Return a bucket of piece coverages.
    my $cover = {};

    # Get the set of pieces and ids.
    my %pieces;
    @pieces{values %{+Chess::Rep::PIECE_TO_ID()}} = keys %{+Chess::Rep::PIECE_TO_ID()};

    # Look at each board position.
    for my $row (0 .. 7) {
        for my $col (0 .. 7) {
            my $p = $self->get_piece_at($row, $col); # decimal of index
            if ($p) {
                my $c = Chess::Rep::piece_color($p); # 0=black, 0x80=white
                my $i = Chess::Rep::get_index($row, $col); # $row << 4 | $col
                my $f = Chess::Rep::get_field_id($i); # A-H, 1-8

                $cover->{$f}{occupant} = $pieces{$p};
                $cover->{$f}{piece} = $p;
                $cover->{$f}{color} = $c;
                $cover->{$f}{index} = $i;

                # Invert the FEN to compute all possible moves, threats and protections.
                my $inverted = _invert_fen($fen, $row, $col, $c);
                $self->set_from_fen($inverted);

                # Set the "next to move" color to the piece.
                $self->to_move($c);

                # Recompute the move status.
                $self->compute_valid_moves;
                # Collect the moves of the piece.
                my $moves = [ map { $_->{to} } grep { $_->{from} == $i } @{ $self->status->{moves} } ];

                # Reset original game FEN.
                $self->set_from_fen($fen);

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
    my $suffix = '';
    if ($fen =~ /^(.+?)\s(.*)$/) {
        ($fen, $suffix) = ($1, $2);
    }
    # Convert pieces to all black or all white, given the piece color.
    $fen = $color ? lc $fen : uc $fen;
    # Split the FEN into rows.
    my @fen = split /\//, $fen; # rows: 7..0, cols: 0..7
    # The FEN sections are the rows reversed.
    $row = 7 - $row;

    my $position = 0;
    my $counter = 0;
    # Inspect each character in the row to find the position of the piece to invert.
    for my $i (split //, $fen[$row]) {
        # Increment the position if we are on a digit.
        if ($i =~ /^\d$/) {
            $position += $i;
        }
        else {
            # Invert the piece character (to its original state) or increment the position.
            if ($position == $col) {
                substr($fen[$row], $counter, 1) = $i ^ "\x20";
                last;
            }
            else {
                # Next!
                $position++;
            }
        }

        # Increment the loop counter.
        $counter++;
    }

    return join('/', @fen) . " $suffix";
}

1;
__END__

=head1 TO DO

Make images and animations of coverage(s).

=head1 SEE ALSO

* The code in the C<eg/> and C<t/> directories.

* L<Chess::Rep>

=cut
