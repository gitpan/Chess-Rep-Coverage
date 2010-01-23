#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('Chess::Rep::Coverage') }
my $d = eval { Chess::Rep::Coverage->new };
isa_ok $d, 'Chess::Rep::Coverage';
my $g = eval { Chess::Rep::Coverage->new('rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2') };
diag($g->dump_pos);
my $c = $g->coverage();
#use Data::Dumper;local$Data::Dumper::Indent=1;local$Data::Dumper::Terse=1;local$Data::Dumper::Sortkeys=1;
#warn Dumper($c);
isa_ok $c, 'HASH';
is $c->{H8}{occupant}, 'black rook 16', 'H8 occupant';
ok !$c->{G1}{occupant}, 'G1 unoccupied';
