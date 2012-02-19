package Chess::Rep::Coverage;
# ABSTRACT: Expose chess ply potential energy

=head1 NAME

Chess::Rep::Coverage - Expose chess ply potential energy

=cut

use strict;
use warnings;

use base 'Chess::Rep';

our $VERSION = '0.08';

=head1 SYNOPSIS

  use Chess::Rep::Coverage;

  my $g = Chess::Rep::Coverage->new();
  print $g->board();

  $g->set_from_fen('8/8/8/3pr3/4P3/8/8/8 w ---- - 0 1');
  $c = $g->coverage(); # Recalculate board status
  print Dump($c);
  print $g->board();

=head1 DESCRIPTION

This module exposes the "potential energy" of a chess ply by returning
a hash reference of the board positions, pieces and their "attack or
protection status."

=head1 METHODS

=head2 new()

Return a new C<Chess::Coverage> object.

=head2 coverage()

  $x = Chess::Rep::Coverage::coverage();

Set the C<cover> attribute and return a data structure, keyed on board
position, showing

  occupant            => Human readable piece name
  color               => Color number of the occupant
  index               => The C<Chess::Rep/Position> board position index
  move                => List of positions that are legal moves by this piece
  protects            => List of positions that are protected by this piece
  threatens           => List of positions that are threatened by this piece
  is_protected_by     => List of positions that protect this piece
  is_threatened_by    => List of positions that threaten this piece
  white_can_move_here => List of white piece positions that can move to this position
  black_can_move_here => List of black piece positions that can move to this position

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
                $cover->{$f}{protects} = [];
                $cover->{$f}{threatens} = [];

                # Kings are special-cased.
                if ($p == 4 or $p == 132) {
                    # Collect the moves of the piece.
                    $cover->{$f}{move} = $self->_fetch_new_moves($f, $i, $c);

                    # Inspect the positions surrounding the king.
                    for my $m ([$row, $col + 1], [$row + 1, $col], [$row + 1, $col + 1], [$row + 1, $col - 1],
                               [$row, $col - 1], [$row - 1, $col], [$row - 1, $col - 1], [$row - 1, $col + 1]
                    ) {
                        my $x = Chess::Rep::get_index(@$m);
                        next if $x & 0x88;
                        $self->_set_piece_status($cover, $f, $x, $c);
                    }
                }
                else {
                    # Invert the FEN to compute all possible moves, threats and protections.
                    my $inverted = _invert_fen($fen, $row, $col, $c);
                    $self->set_from_fen($inverted);

                    # Collect the moves of the piece.
                    $cover->{$f}{move} = $self->_fetch_new_moves($f, $i, $c);

                    # Reset original game FEN.
                    $self->set_from_fen($fen);

                    # Find the threats and protections by the piece.
                    $self->_set_piece_status($cover, $f, $_, $c) for @{$cover->{$f}{move}};
                }
            }
        }
    }

    # Compute piece and position status.
    for my $piece (keys %$cover) {
        $cover->{$piece}{is_threatened_by} ||= [];
        $cover->{$piece}{is_protected_by} ||= [];

        # Compute protection status of a piece.
        for my $index (@{$cover->{$piece}{protects}}) {
            my $f = Chess::Rep::get_field_id($index); # A-H, 1-8
            push @{$cover->{$f}{is_protected_by}}, $cover->{$piece}{index};
        }

        # Compute threat status of a piece.
        for my $index (@{$cover->{$piece}{threatens}}) {
            my $f = Chess::Rep::get_field_id($index); # A-H, 1-8
            push @{$cover->{$f}{is_threatened_by}}, $cover->{$piece}{index};
        }

        # Compute move status of a position.
        for my $index (@{$cover->{$piece}{move}}) {
            my $p = $self->get_piece_at($index);
            if (!$p) {
                my $f = Chess::Rep::get_field_id($index); # A-H, 1-8

                $cover->{$f}{white_can_move_here} ||= [];
                $cover->{$f}{black_can_move_here} ||= [];

                my $color = $cover->{$piece}{color} ? 'white' : 'black';
                push @{$cover->{$f}{$color . '_can_move_here'}}, $cover->{$piece}{index};
            }
        }
    }

    # Set the object coverage attribute.
    $self->cover($cover);

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

=head2 cover()

  $self->cover($c);
  $c = $self->cover();

Accessor for the game coverage.

=cut

sub _fetch_new_moves {
    my $self = shift;
    my($field, $index, $color) = @_;
    # Set the "next to move" color to the piece.
    $self->to_move($color);
    # Recompute the move status.
    $self->compute_valid_moves;
    # Collect the moves of the piece.
    return [ map { $_->{to} } grep { $_->{from} == $index } @{ $self->status->{moves} } ];
}

sub _set_piece_status {
    my $self = shift;
    my($cover, $field, $index, $color) = @_;
    my $p = $self->get_piece_at($index);
    return unless $p;
    # Set the protection or threat status of the piece.
    if (Chess::Rep::piece_color($p) == $color) {
        # Any piece can be protected but a king.
        push @{$cover->{$field}{protects}}, $index
            unless $p == 4 or $p == 132;
    }
    else {
        push @{$cover->{$field}{threatens}}, $index;
    }
}

sub cover {
    my $self = shift;
    $self->{cover} = shift if @_;
    return $self->{cover};
}

=head2 board()

  print $self->board();

Return an ASCII board layout with threats, protections and move
statuses.

Protection and threat is indicated by C<p/t>.  White and black
movement is indicated by C<w:b>.

For example, the FEN C<8/8/8/3pr3/4P3/8/8/8 w ---- - 0 1> is rendered
as:

       A     B     C     D     E     F     G     H
    +-----+-----+-----+-----+-----+-----+-----+-----+
  1 |     |     |     |     |     |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  2 |     |     |     |     |     |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  3 |     |     |     |     |     |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  4 |     |     |     | 0:1 | 0/2 |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  5 |     |     |     | 1/1 | 0/0 | 0:1 | 0:1 | 0:1 |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  6 |     |     |     |     | 0:1 |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  7 |     |     |     |     | 0:1 |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+
  8 |     |     |     |     | 0:1 |     |     |     |
    +-----+-----+-----+-----+-----+-----+-----+-----+

This means that, 1) the black pawn at D5 can move to D4 and can
capture the white pawn at E4; 2) the white pawn at E4 can neither move
nor capture; 3) the black rook at E5 protects the black pawn at D5,
can capture the white pawn at E4 and can move to F5 through H5 or E6
through E8.

=cut

sub board {
    my $self = shift;
    my %args = @_;

    # Compute coverage if has not been done yet.
    $self->coverage() unless $self->cover();

    # Start rendering the board.
    my $board = _ascii_board('header');
    $board .= _ascii_board('row');

    # Look at each board position.
    for my $row (1 .. 8) {
        # Render the beginning of the row.
        $board .= $row . _ascii_board('cell_pad');

        for my $col ('A' .. 'H') {
            # Render a new cell.
            $board .= _ascii_board('new_cell');

            # Inspect the coverage at the column and row position.
            if ($self->cover()->{$col . $row}) {
                if (exists $self->cover()->{$col . $row}->{is_protected_by} and
                    exists $self->cover()->{$col . $row}->{is_threatened_by}
                ) {
                    # Show threat and protection status.
                    my $protects = $self->cover()->{$col . $row}->{is_protected_by};
                    my $threats  = $self->cover()->{$col . $row}->{is_threatened_by};
                    $board .= @$protects . '/' . @$threats;
#                    $board .= $self->cover()->{$col . $row}->{occupant};
                }
                elsif (exists $self->cover()->{$col . $row}->{white_can_move_here} and
                       exists $self->cover()->{$col . $row}->{black_can_move_here}
                ) {
                    # Show player movement status.
                    my $whites = $self->cover()->{$col . $row}->{white_can_move_here};
                    my $blacks = $self->cover()->{$col . $row}->{black_can_move_here};
                    $board .= @$whites . ':' . @$blacks;
#                    $board .= $self->cover()->{$col . $row}->{occupant};
                }
            }
            else {
                # Render an empty cell.
                $board .= _ascii_board('empty_cell');
            }

            # Render the end of a cell.
            $board .= _ascii_board('cell_pad');
            # Render the end of a column if we have reached the last.
            $board .= _ascii_board('col_edge') if $col eq 'H';
        }

        # Render the end of a row.
        $board .= "\n" . _ascii_board('row');
    }

    return $board;
}

sub _ascii_board {
    # perl -Ilib -MChess::Rep::Coverage -e'$g=Chess::Rep::Coverage->new;print $g->board'
    my $section = shift;

    my ($cells, $size, $empty) = (8, 5, 3);

    my %board = (
        cell_pad => ' ',
        col_edge => '|',
        corner   => '+',
        row_edge => '-',
    );
    $board{edge} = $board{corner} . ($board{row_edge} x $size);
    $board{row} = ($board{cell_pad} x ($empty - 1)) . ($board{edge} x $cells) . $board{corner} . "\n";
    $board{empty_cell} = $board{cell_pad} x $empty;
    $board{new_cell} = $board{col_edge} . $board{cell_pad};
    $board{header} = ($board{cell_pad} x $size) . join($board{cell_pad} x $size, 'A' .. 'H') . "\n";

    return $board{$section};
}


1;
__END__

=head1 TO DO

Make images and animations of coverage(s).

=head1 SEE ALSO

* The code in the C<t/> directory.

* L<Chess::Rep>

=cut
