#!perl -T
use strict;
use warnings;
use Data::Dumper;local$Data::Dumper::Indent=1;local$Data::Dumper::Terse=1;local$Data::Dumper::Sortkeys=1;
use Test::More tests => 7;
BEGIN { use_ok('Chess::Rep::Coverage') }
my $g = eval { Chess::Rep::Coverage->new };
isa_ok $g, 'Chess::Rep::Coverage';
diag('Making a series of moves...');
my $x = $g->go_move('PD4'); # w
   $x = $g->go_move('PC5'); # b
   $x = $g->go_move('NF3'); # w
   $x = $g->go_move('PE5'); # b
my $c = $g->covers(-as_field => 1);
isa_ok $c, 'HASH';
diag($g->to_move ? 'W' : 'b', ' to move');
diag(join("\n",    '|A|B|C|D|E|F|G|H|', '-' x 17));     # Legend:
# |r|n|b|q|k|b|n|r|8| | | | | | | | |8|0|1|1|1|1|1|1|0| # | | uncontrolled cell
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| # |/| white controlled
# |p|p| |p| |p|p|p|7| | | | | | | | |7|1|1|\|3|\|1|1|1| # |\| black controlled
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| # |0| protected by no pieces
# | | | | | | | | |6| | | | | | | |/|6|\|\|\|\|\|\|\|\| # |1| protected by one piece
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| # |2| protected by two pieces, etc.
# | | |p| |p| | | |5| | !1| !2| |/| |5| | |1| |0| |\| | # !3| attacked opponent by three pieces!
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-|
# | | | |P| | | | |4| | | |2| |/| | |4| |\| !2| |\| |\|
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-|
# | | | | | |N| | |3|/|/|/|/|/|2|/|/|3| | | | | | | | |
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-|
# |P|P|P| |P|P|P|P|2|1|1|1|/|3|1|1|2|2| | | | | | | | |
# |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-| |-+-+-+-+-+-+-+-|
# |R|N|B|Q|K|B| |R|1|0|1|1|1|2|2|/|0|1| | | | | | | | |
diag($g->dump_pos);
#warn Dumper($c);
my $i = 'D4';   # white pawn
my $j = 'attacks';
is_deeply $c->{$i}{$j}, [qw(E5 C5)], "$i $j [@{$c->{$i}{$j}}]";
$j = 'protects';
ok !exists $c->{$i}{$j}, "$i $j nothing";
$i = 'F3';      # white knight
$j = 'attacks';
is_deeply $c->{$i}{$j}, ['E5'], "$i $j [@{$c->{$i}{$j}}]";
$j = 'protects';
is_deeply $c->{$i}{$j}, [qw(D4 H2 E1)], "$i $j [@{$c->{$i}{$j}}]";