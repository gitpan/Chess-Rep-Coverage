#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Chess::Rep::Coverage') }

my $g = eval { Chess::Rep::Coverage->new() };
print $@ if $@;
isa_ok $g, 'Chess::Rep::Coverage';

my $fen = Chess::Rep::FEN_STANDARD; # Default starting position
diag($fen);
my $c = $g->coverage();
isa_ok $c, 'HASH';
is $c->{H8}{occupant}, 'r', 'H8 occupant';
is $c->{H8}{piece}, 16, 'H8 piece';
is $c->{H8}{color}, 0, 'H8 color';
is $c->{H8}{index}, 119, 'H8 index';
is_deeply $c->{H8}{move}, [103, 118], 'H8 move';
is_deeply $c->{H8}{protects}, [103, 118], 'H8 protects';

#$fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'; # after the move 1. e4
#$fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2'; # after 1. ... c5
#$fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2'; # after 2. Nf3

$fen = '8/8/8/3pr3/4P3/8/8/8 w ---- - 0 1'; # 3 pieces, w/b pawn mutual threat, black rook threat
diag($fen);
$g->set_from_fen($fen);
$c = $g->coverage();
is_deeply $c->{D5}{move}, [51, 52], 'D5 move';
is_deeply $c->{D5}{threatens}, [52], 'D5 threatens';
is_deeply $c->{E4}{move}, [67], 'E4 move';
is_deeply $c->{E4}{threatens}, [67], 'E4 threatens';
is_deeply $c->{E5}{move}, [qw(69 70 71 84 100 116 52 67)], 'E5 move';
is_deeply $c->{E5}{protects}, [67], 'E5 protects';
is_deeply $c->{E5}{threatens}, [52], 'E5 threatens';

#$fen = '8/8/8/8/8/8/8/8 w ---- - 0 1'; # No pieces
#$fen = '8/8/8/3p4/8/8/8/8 w ---- - 0 1'; # 1 black piece
#$fen = '8/8/8/8/4P3/8/8/8 w ---- - 0 1'; # 1 white piece
#$fen = 'pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp b ---- - 0 1';
#$fen = 'r6R/8/8/8/8/8/8/8 w ---- - 0 1'; # Opposing rooks
#$fen = 'r7/P7/8/8/8/8/8/8 w ---- - 0 1'; # black rook threatens white pawn
#$fen = '1p6/P7/8/8/8/8/8/8 w ---- - 0 1'; # black pawn vs white pawn
#$fen = '8/8/8/3p4/4P3/8/8/8 w ---- - 0 1'; # 2 pieces, w/b pawn mutual threat
#$fen = '8/8/8/3Pr3/8/8/8/8 w ---- - 0 1'; # 2 pieces, single black threat
#$fen = '8/8/8/3pr3/8/8/8/8 w ---- - 0 1'; # 2 pieces, single black protection
#$fen = 'rp6/P7/8/8/8/8/8/8 w ---- - 0 1'; # 3 pieces, w/b pawn mutual threat, black rook threat

#use Data::Dumper;warn Data::Dumper->new([$c])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;

my $x = $g->cover();
is_deeply $x, $c, 'cover accessor';
$x = $g->cover({});
is_deeply $x, {}, 'cover set';
