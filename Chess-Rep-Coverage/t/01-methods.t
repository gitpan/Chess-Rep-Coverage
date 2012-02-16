#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Chess::Rep::Coverage') }

my $class = 'Chess::Rep::Coverage';
my $g = eval { $class->new() };
print $@ if $@;
isa_ok $g, $class;

#warn $g->get_fen, "\n";

#my $fen = Chess::Rep::FEN_STANDARD; # Starting position
#my $fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'; # after the move 1. e4
#my $fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2'; # after 1. ... c5
#my $fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2'; # after 2. Nf3
#my $fen = 'pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp b ---- - 0 1';
#my $fen = 'r6R/8/8/8/8/8/8/8 w ---- - 0 1';
my $fen = 'rp6/P7/8/8/8/8/8/8 w ---- - 0 1';
#my $fen = 'r7/P7/8/8/8/8/8/8 w ---- - 0 1';
#my $fen = '1p6/P7/8/8/8/8/8/8 w ---- - 0 1';
#my $fen = '1p6/8/8/8/8/8/8/8 w ---- - 0 1';
#my $fen = '8/8/8/8/8/8/8/8 w ---- - 0 1';
#my $fen = '8/8/8/3p4/4P3/8/8/8 w ---- - 0 1';
#my $fen = '8/8/8/3p4/8/8/8/8 w ---- - 0 1';
#my $fen = '8/8/8/8/4P3/8/8/8 w ---- - 0 1';
#my $fen = '8/P7/8/8/8/8/8/8 w ---- - 0 1';
warn"FEN: $fen\n";

$g->set_from_fen($fen);

my $c = $g->coverage();
isa_ok $c, 'HASH';
#is $c->{H8}{occupant}, 'black rook 16', 'H8 occupant';
use Data::Dumper;warn Data::Dumper->new([$c])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;
