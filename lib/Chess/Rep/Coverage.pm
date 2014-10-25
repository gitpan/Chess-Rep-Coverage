# $Id: Coverage.pm 913 2008-08-06 02:47:37Z gene $

package Chess::Rep::Coverage;
our $VERSION = '0.0401';
use strict;
use warnings;
use base 'Chess::Rep';

sub coverage {
    my $self = shift;
    my %name = (
        0x01 => 'black pawn',
        0x02 => 'black knight',
        0x04 => 'black king',
        0x08 => 'black bishop',
        0x10 => 'black rook',
        0x20 => 'black queen',
        0x81 => 'white pawn',
        0x82 => 'white knight',
        0x84 => 'white king',
        0x88 => 'white bishop',
        0x90 => 'white rook',
        0xA0 => 'white queen',
    );

    my $cover = {};

    my $status = $self->status->{moves};

    for my $row (0 .. 7) {
        for my $col (0 .. 7) {
            my $i = Chess::Rep::get_index($row, $col);
            my $f = Chess::Rep::get_field_id($i);
            my $c = $self->piece_color($i);
            my $p = $self->get_piece_at($row, $col) || '';

            $cover->{$f}{index} = $i;

            my $moves = [];

            if ($p) {
                $cover->{$f}{occupant} = $name{$p} .' '. $p;
                $moves = [ map { $_->{to} } grep { $_->{from} == $i } @$status ];
                $cover->{$f}{move} = $moves if @$moves;
            }

            for my $color (0, 0x80) {
                $cover->{$f}{ $c == $color ? 'protected' : 'threatened' }++
                    if $p && $self->is_attacked($i, $color);
            }
        }
    }

    return $cover;
}

1;

__END__

=head1 NAME

Chess::Rep::Coverage - Expose chess ply potential energy

=head1 SYNOPSIS

  use Chess::Rep::Coverage;
  $g = Chess::Rep::Coverage->new();
  $c = $g->coverage();

=head1 DESCRTIPTION

This module exposes the "potential energy" of a chess ply by returning
a hash reference of the board positions, pieces and their "attack
status."

* This module was a lot more complicated and slower, in the past.
Modern chess packages have allowed me to simplify this over time.

* Previous versions of this module B<listed> the board positions that
threatened or protected a given position.  This module does the
reverse (for the moment) and shows if positions are threatened or
protected with a simple true value.

=head1 METHODS

=head2 new()

Return a new C<Chess::Coverage> object.

=head2 coverage()

Return a data structure, keyed on board position, showing

  occupant   => Human readable string of the piece name and color
  index      => The C<Chess::Rep/Position> board position index.
  move       => List of positions that are legal moves by the occupying piece
  protected  => True (1) if the occupying piece is protected by its own color
  threatened => True (1) if the occupying piece is threatened by the opponent

=head1 TO DO

Get C<Chess::Rep> to return the indices of the attackers.

Make additional methods (or plugins) produce images and animations of
the coverage.

=head1 SEE ALSO

L<Chess::Rep>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007-2008, Gene Boggs.

This code is licensed under the same terms as Perl itself.

=cut
